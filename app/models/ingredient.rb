class Ingredient < ActiveRecord::Base
  include BodyTracking::Formula

  enum group: {
    other: 0,
    meat: 1
  }

  belongs_to :project, required: true
  belongs_to :ref_unit, class_name: 'Unit', required: true
  belongs_to :source, required: false

  has_many :nutrients, inverse_of: :ingredient, dependent: :destroy, validate: true
  validates :nutrients, presence: true
  accepts_nested_attributes_for :nutrients, allow_destroy: true, reject_if: proc { |attrs|
    attrs['quantity_id'].blank? && attrs['amount'].blank?
  }
  # Nutrient quantity_id uniqueness check for nested attributes
  validate do
    quantities = self.nutrients.map { |n| n.quantity_id }
    if quantities.length != quantities.uniq.length
      errors.add(:nutrients, :duplicated_quantity)
    end
  end

  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :ref_amount, numericality: {greater_than: 0}
  validates :group, inclusion: {in: groups.keys}

  after_initialize do
    if new_record?
      self.ref_amount ||= 100
      units = self.project.units
      self.ref_unit ||= units.find_by(shortname: 'g') || units.first
      self.group ||= :other
      self.hidden = false if self.hidden.nil?
    end
  end

  def self.filter(project, filters = {}, requested_q = [])
    ingredients = all

    if filters[:name].present?
      ingredients = ingredients.where("name LIKE ?", "%#{filters[:name]}%")
    end

    if filters[:visibility].present?
      ingredients = ingredients.where(hidden: filters[:visibility] == "1" ? false : true)
    end

    formula_q = if filters[:nutrients].present?
                  project.quantities.new(name: '__internal_q',
                                         formula: filters[:nutrients],
                                         domain: :diet)
                end
    apply_formula = formula_q.present? && formula_q.valid?

    result =
      if !requested_q.empty? || apply_formula
        computed = ingredients.compute_nutrients(requested_q, apply_formula && formula_q)
        requested_q.present? ? computed : [computed[0]]
      else
        [ingredients]
      end
    result.push(formula_q)
  end

  def self.compute_nutrients(requested_q, filter_q = nil)
    ingredients = all
    unchecked_q = requested_q.map { |q| [q, nil] }
    unchecked_q << [filter_q, nil] if filter_q

    nutrients = Hash.new { |h,k| h[k] = {} }
    Nutrient.where(ingredient: ingredients).includes(:quantity, :unit)
      .order('quantities.lft')
      .pluck('quantities.name', :ingredient_id, :amount, 'units.shortname')
      .each { |q_name, i_id, a, u_id| nutrients[q_name][i_id] = [a, u_id] }

    extra_q = nutrients.keys - requested_q.pluck(:name)

    completed_q = {}
    # FIXME: loop should finish unless there is circular dependency in formulas
    # for now we don't guard against that
    while !unchecked_q.empty?
      q, deps = unchecked_q.shift

      # quantity not computable (no formula) or not requiring calculation/computed
      if q.formula.blank? || (nutrients[q.name].length == ingredients.count)
        completed_q[q.name] = nutrients.delete(q.name) { {} }
        next
      end

      # quantity with formula requires refresh of dependencies availability
      if deps.nil? || !deps.empty?
        deps ||= q.formula_quantities
        deps.reject! { |q| completed_q.has_key?(q.name) }
        deps.each { |q| unchecked_q << [q, nil] unless unchecked_q.index { |u| u[0] == q } }
      end

      # quantity with formula has all dependencies satisfied, requires calculation
      if deps.empty?
        input_q = q.formula_quantities
        inputs = ingredients.select { |i| nutrients[q.name][i.id].nil? }.map do |i|
          [
            i,
            input_q.map do |i_q|
              # FIXME: result for computation with nil values (substituted with 0s)
              # should be marked as not precise
              nutrient_data = completed_q[i_q.name][i.id] || [0, nil]
              [i_q.name, nutrient_data[0]]
            end.to_h
          ]
        end
        q.calculate(inputs).each { |i, result| nutrients[q.name][i.id] = result }
        unchecked_q.unshift([q, deps])
        next
      end

      # quantity still has unsatisfied dependencies, move to the end of queue
      unchecked_q << [q, deps]
    end

    all_q = nutrients.merge(completed_q)
    [
      filter_q ? ingredients.to_a.keep_if { |i| all_q[filter_q.name][i.id] } : ingredients,
      ingredients.map { |i| requested_q.map { |q| [q.name, all_q[q.name][i.id]] } },
      ingredients.map do |i|
        extra_q.map { |q_name| [q_name, all_q[q_name][i.id]] if all_q[q_name][i.id] }
      end
    ]
  end
end
