class FoodsController < ApplicationController
  require 'csv'

  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :init_session_filters
  before_action :find_project_by_project_id,
    only: [:index, :new, :create, :nutrients, :filter, :autocomplete, :import]
  before_action :find_quantity_by_quantity_id, only: [:toggle_exposure]
  before_action :find_food, only: [:edit, :update, :destroy, :toggle]
  before_action :authorize

  def index
    prepare_foods
  end

  def new
    @food = @project.foods.new
    @food.nutrients.new(unit: @food.ref_unit)
  end

  def create
    @food = @project.foods.new(food_params)
    if @food.save
      flash[:notice] = 'Created new food'
      prepare_items
    else
      @food.nutrients.new(unit: @food.ref_unit) if @food.nutrients.empty?
      render :new
    end
  end

  def edit
  end

  def update
    if @food.update(food_params)
      flash[:notice] = 'Updated food'
      prepare_items
      render :index
    else
      render :edit
    end
  end

  def destroy
    if @food.destroy
      flash[:notice] = 'Deleted food'
    end
  end

  def toggle
    @food.toggle_hidden!
    prepare_items
  end

  def nutrients
    prepare_nutrients
  end

  def toggle_exposure
    @project.nutrient_exposures.toggle!(@quantity)
    prepare_nutrients
  end

  def filter
    session[:f_filters] = params.permit(:name, :visibility, formula: [:code, :zero_nil])
    prepare_items
    render :index
  end

  def autocomplete
    @foods = @project.foods.where("name LIKE ?", "%#{params[:term]}%")
  end

  def import
    warnings = []

    if params.has_key?(:file)
      quantities = @project.quantities.diet.map { |q| [q.name, q] }.to_h
      units = @project.units.map { |u| [u.shortname, u] }.to_h
      sources = @project.sources.map { |s| [s.name, s] }.to_h
      foods_params = []
      column_units = {}

      CSV.foreach(params[:file].path, headers: true).with_index(2) do |row, line|
        r = row.to_h
        unless r.has_key?('Name')
          warnings << "Line 1: required 'Name' column is missing" if line == 2
        end
        if r['Source'].present? && sources[r['Source']].blank?
          warnings << "Line #{line}: unknown source name #{r['Source']}"
        end

        f_params = {
          name: r.delete('Name'),
          notes: r.delete('Notes'),
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
            f_params.update({
              ref_amount: amount.to_d,
              ref_unit: unit
            })
          else
            f_params[:nutrients_attributes] << {
              quantity: quantities[quantity],
              amount: amount.to_d,
              unit: unit
            }
          end
        end

        foods_params << f_params
      end
    else
      warnings << 'No file selected'
    end

    if warnings.empty?
      foods = @project.foods.create(foods_params)
      flash[:notice] = "Imported #{foods.map(&:persisted?).count(true)} out of" \
        " #{foods_params.length} foods"
      skipped = foods.select { |f| !f.persisted? }
      if skipped.length > 0
        skipped_desc = skipped.map { |f| "#{f.name} - #{f.errors.full_messages.join(', ')}" }
        flash[:warning] = "Foods skipped due to errors:<br>" \
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
    session[:f_filters] ||= {formula: {}}
  end

  def food_params
    params.require(:food).permit(
      :name,
      :notes,
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

  def prepare_items
    params[:view] == 'index' ? prepare_foods : prepare_nutrients
  end

  def prepare_foods
    @foods, @filter_q = @project.foods
      .includes(:ref_unit, :source)
      .filter(session[:f_filters])
  end

  def prepare_nutrients
    @quantities = @project.nutrient_quantities.includes(:formula)
    @foods, @requested_n, @extra_n, @filter_q = @project.foods
      .filter(session[:f_filters], @quantities)
  end
end
