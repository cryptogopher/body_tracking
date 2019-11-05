class IngredientsController < ApplicationController
  require 'csv'

  before_action :find_project_by_project_id,
    only: [:index, :nutrients, :create, :import, :filter, :filter_nutrients]
  before_action :find_quantity, only: [:toggle_nutrient_column]
  before_action :find_ingredient, only: [:destroy, :toggle]
  before_action :authorize

  def index
    @ingredient = @project.ingredients.new
    # passing attr for Nutrient after_initialize
    @ingredient.nutrients.new(ingredient: @ingredient)

    prepare_ingredients
    @ingredients << @ingredient
  end

  def nutrients
    @ingredient = @project.ingredients.new
    @ingredient.nutrients.new(ingredient: @ingredient)
    prepare_nutrients
  end

  def toggle_nutrient_column
    @quantity.toggle_primary!
    prepare_nutrients
  end

  def create
    @ingredient = @project.ingredients.new(ingredient_params)
    if @ingredient.save
      flash[:notice] = 'Created new ingredient'
      redirect_to :back
    else
      prepare_ingredients
      @ingredient.nutrients.new(ingredient: @ingredient) if @ingredient.nutrients.empty?
      render :index
    end
  end

  def destroy
    # FIXME: don't destroy if any meal depend on ingredient
    if @ingredient.destroy
      flash[:notice] = 'Deleted ingredient'
    end
    prepare_ingredients
    render :toggle
  end

  def toggle
    @ingredient.update(hidden: !@ingredient.hidden)
    prepare_ingredients
  end

  def filter
    session[:filters] = params[:filters]
    prepare_ingredients
    render :toggle
  end

  def filter_nutrients
    session[:filters] = params[:filters]
    prepare_nutrients
    render :toggle_nutrient_column
  end

  def import
    warnings = []

    if params.has_key?(:file)
      quantities = @project.quantities.map { |q| [q.name, q] }.to_h
      units = @project.units.map { |u| [u.shortname, u] }.to_h
      sources = @project.sources.map { |s| [s.name, s] }.to_h
      ingredients_params = []
      column_units = {}

      CSV.foreach(params[:file].path, headers: true).with_index(2) do |row, line|
        r = row.to_h
        unless r.has_key?('Name')
          warnings << "Line 1: required 'Name' column is missing" if line == 2
        end
        if r['Source'].present? && sources[r['Source']].blank?
          warnings << "Line #{line}: unknown source name #{r['Source']}"
        end

        i_params = {
          name: r.delete('Name'),
          ref_amount: 100.0,
          ref_unit: units['g'],
          group: r.delete('Group') || :other,
          source: sources[r['Source']],
          source_ident: r.delete('SourceIdent'),
          nutrients_attributes: []
        }

        r.each do |col, val|
          if col.blank?
            warnings << "Line 1: column header missing" if line == 2
            next
          end
          quantity, quantity_unit_sn, * = col.rstrip.partition(/\[.*\]$/)
          quantity.strip!
          if line == 2
            unless quantities[quantity]
              warnings << "Line 1: unknown quantity name #{quantity}"
            end
            if quantity_unit_sn.present?
              column_units[quantity] = units[quantity_unit_sn[1..-2]]
              warnings << "Line 1: unknown unit #{quantity_unit_sn}" \
                " in column #{col}" unless column_units[quantity]
            end
          end

          next if val.blank?
          amount, amount_unit_sn, * = val.rstrip.partition(/\[.*\]$/)
          unit = nil
          if amount_unit_sn.present?
            unit = units[amount_unit_sn[1..-2]]
            warnings << "Line #{line}: unknown unit name #{amount_unit_sn}" \
              " in column #{col}" unless unit
          else
            unit = column_units[quantity]
            # Suppress row warning if column unit error has been reported eariler
            unless unit || column_units.has_key?(quantity)
              warnings << "Line #{line}: unknown unit for column #{col}"
            end
          end

          next if quantities[quantity].blank?
          if quantity == 'Reference'
            i_params.update({
              ref_amount: amount.to_d,
              ref_unit: unit
            })
          else
            i_params[:nutrients_attributes] << {
              quantity: quantities[quantity],
              amount: amount.to_d,
              unit: unit
            }
          end
        end

        ingredients_params << i_params
      end
    else
      warnings << 'No file selected'
    end

    if warnings.empty?
      ingredients = @project.ingredients.create(ingredients_params)
      flash[:notice] = "Imported #{ingredients.map(&:persisted?).count(true)} out of" \
        " #{ingredients_params.length} ingredients"
      skipped = ingredients.select { |i| !i.persisted? }
      if skipped.length > 0
        skipped_desc = skipped.map { |i| "#{i.name} - #{i.errors.full_messages.join(', ')}" }
        flash[:warning] = "Ingredients skipped due to errors:<br>" \
          " #{skipped_desc.join('<br>').truncate(1024)}"
      end
    else
      warnings.unshift("Problems encountered during import - fix and try again:")
      flash[:warning] = warnings.join("<br>").truncate(1024, omission: '...(and other)')
    end
    redirect_to :back
  end

  private

  def ingredient_params
    params.require(:ingredient).permit(
      :name,
      :ref_amount,
      :ref_unit_id,
      :group,
      :source_id,
      :source_ident,
      nutrients_attributes:
      [
        :id,
        :quantity_id,
        :amount,
        :unit_id,
        :_destroy
      ]
    )
  end

  # :find_* methods are called before :authorize,
  # @project is required for :authorize to succeed
  def find_ingredient
    @ingredient = Ingredient.find(params[:id])
    @project = @ingredient.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def prepare_ingredients
    @ingredients = filter_ingredients.includes(:ref_unit, :source)
  end

  def prepare_nutrients
    @quantities = @project.quantities.where(primary: true)
    compute_nutrients(filter_ingredients, @quantities)

    @primary_nutrients = {}
    @extra_nutrients = {}
    ingredients.each do |i|
      @primary_nutrients[i] = {}
      @extra_nutrients[i] = {}
      i.nutrients.sort_by { |n| n.quantity.lft }.each do |n|
        if @primary_quantities.include?(n.quantity)
          @primary_nutrients[i][n.quantity_id] = "#{n.amount} [#{n.unit.shortname}]"
        else
          @extra_nutrients[i][n.quantity.name] = "#{n.amount} [#{n.unit.shortname}]"
        end
      end
    end
  end

  def compute_nutrients(ingredients, requested_q)
    unchecked_q = requested_q.map { |q| [q, nil] }.to_h

    nutrients = Hash.new { |h,k| h[k] = {} }
    Nutrient.joins(:ingredient).where(ingredient: ingredients)
      .pluck(:quantity_id, :ingredient_id, :amount, :unit_id)
      .each { |[q_id, i_id, a, u_id]| nutrients[q_id][i_id] = [a, u_id] }

    completed_q = {}
    # FIXME: loop should finish unless there is circular dependency in formulas
    # for now we don't guard against that
    while !unchecked_q.empty?
      q, deps = unchecked_q.shift

      if q.formula.blank? || (nutrients[q.id].length == ingredients.length)
        completed_q[q] = nutrients.delete(q.id)
        next
      end

      if deps.nil? || !deps.empty?
        formula_deps = deps || q.formula_quantities
        unchecked_q[q] = formula_deps.delete_if { |q| completed_q.has_key?(q) }
        unchecked_q[q].each { |q| unchecked_q[q] = nil unless unchecked_q.has_key?(q) }
        deps = unchecked_q[q]
      end

      if deps.empty?
        ingredients.each do |i|
          inputs = nutrients.map { |q_name, *| [q_name, nutrients[q_name][i.id][0]] }.to_h
          nutrients[q.name][i.id] = q.calculate(inputs)
        end
      end
      unchecked_q[q] = deps
    end
  end

  def filter_ingredients
    filters = session[:filters] || {}
    ingredients = @project.ingredients
    if filters[:name].present?
      ingredients = ingredients.where("name LIKE ?", "%#{filters[:name]}%")
    end
    if filters[:visibility].present?
      ingredients = ingredients.where(hidden: filters[:visibility] == "1" ? false : true)
    end
    ingredients
  end
end
