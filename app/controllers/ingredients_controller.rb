class IngredientsController < ApplicationController
  require 'csv'

  before_action :init_session_filters
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
    @ingredient.toggle_hidden!
    prepare_ingredients
  end

  def filter
    session[:i_filters] = params[:filters]
    prepare_ingredients
    render :toggle
  end

  def filter_nutrients
    session[:i_filters] = params[:filters]
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

  def init_session_filters
    session[:i_filters] ||= {}
  end

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
    @ingredients, @formula_q = @project.ingredients.includes(:ref_unit, :source)
      .filter(@project, session[:i_filters])
  end

  def prepare_nutrients
    @quantities = @project.quantities.where(primary: true)
    ingredients, requested_n, extra_n, @formula_q = @project.ingredients
      .filter(@project, session[:i_filters], @quantities)

    @nutrients = {}
    @extra_nutrients = {}
    ingredients.each_with_index do |i, index|
      @nutrients[i] = []
      requested_n[index].each do |q_name, value|
        amount, unitname = value
        @nutrients[i] << [q_name, amount.nil? ? '-' : "#{amount} [#{unitname || '-'}]"]
      end

      @extra_nutrients[i] = []
      extra_n[index].each do |q_name, value|
        amount, unitname = value
        @extra_nutrients[i] << [q_name, amount.nil? ? '-' : "#{amount} [#{unitname || '-'}]"]
      end
    end
  end
end
