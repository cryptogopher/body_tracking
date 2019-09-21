class IngredientsController < ApplicationController
  require 'csv'

  before_action :find_project_by_project_id, only: [:index, :create, :import]
  before_action :find_ingredient, only: [:destroy]
  before_action :authorize

  def index
    @ingredient = Ingredient.new(project: @project)
    # passing attr for after_initialize
    @ingredient.nutrients.new(ingredient: @ingredient)
    @ingredients = @project.ingredients
  end

  def create
    @ingredient = Ingredient.new(ingredient_params.update(project: @project))
    if @ingredient.save
      flash[:notice] = 'Created new ingredient'
      redirect_to project_ingredients_url(@project)
    else
      @ingredients = @project.ingredients
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

  def import
    warnings = []

    if params.has_key?(:file)
      quantities = @project.quantities.map { |q| [q.name, q] }.to_h
      units = @project.units.map { |u| [u.shortname, u] }.to_h
      ingredients = []
      column_units = {}

      CSV.foreach(params[:file].path, headers: true).with_index(2) do |row, line|
        r = row.to_h
        i = {
          name: r.delete('Name'),
          group: r.delete('Group') || :other,
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
          next if quantities[quantity].blank? || val.blank?

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

          if quantity == 'Reference'
            i.update({
              ref_amount: amount.to_d,
              ref_unit: unit
            })
          else
            i[:nutrients_attributes] << {
              quantity: quantities[quantity],
              amount: amount.to_d,
              unit: unit
            }
          end
        end
        ingredients << i
      end
    else
      warnings << 'No file selected'
    end

    if warnings.present?
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
