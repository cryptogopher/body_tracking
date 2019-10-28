class IngredientsController < ApplicationController
  require 'csv'

  before_action :find_project_by_project_id, only: [:index, :create, :import, :nutrients]
  before_action :find_ingredient, only: [:destroy, :toggle]
  before_action :authorize

  def index
    @ingredient = @project.ingredients.new
    # passing attr for Nutrient after_initialize
    @ingredient.nutrients.new(ingredient: @ingredient)

    @ingredients = @project.ingredients.includes(:ref_unit, :source)
    @ingredients << @ingredient
  end

  def nutrients
    @ingredient = @project.ingredients.new
    @ingredient.nutrients.new(ingredient: @ingredient)

    ingredients = @project.ingredients.includes(:ref_unit, nutrients: [:quantity, :unit])
    @header = @project.quantities.where(primary: true)
    @nutrients = {}
    @descriptions = {}
    ingredients.each do |i|
      @nutrients[i] = {}
      @descriptions[i] = []
      i.nutrients.sort_by { |n| n.quantity.lft }.each do |n|
        if @header.include?(n.quantity)
          @nutrients[i][n.quantity_id] = "#{n.amount} [#{n.unit.shortname}]"
        else
          @descriptions[i] << "#{n.quantity.name}: #{n.amount} [#{n.unit.shortname}]"
        end
      end
    end
    @descriptions.each { |i, v| @descriptions[i] = v.join(", ") }
  end

  def create
    @ingredient = @project.ingredients.new(ingredient_params)
    if @ingredient.save
      flash[:notice] = 'Created new ingredient'
      redirect_to project_ingredients_url(@project)
    else
      @ingredients = @project.ingredients.includes(:ref_unit, :source)
      @ingredient.nutrients.new(ingredient: @ingredient) if @ingredient.nutrients.empty?
      render :index
    end
  end

  def destroy
    # FIXME: don't destroy if any meal depend on ingredient
    if @ingredient.destroy
      flash[:notice] = 'Deleted ingredient'
    end
    redirect_to project_ingredients_url(@project)
  end

  def toggle
    @ingredient.update(hidden: !@ingredient.hidden)
    @ingredients = @project.ingredients.includes(:ref_unit, :source)
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
    redirect_to project_ingredients_url(@project)
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
end
