class Ingredient < ActiveRecord::Base
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

  def self.compute_nutrients(requested_q)
    ingredients = all
    unchecked_q = requested_q.map { |q| [q, nil] }

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

      if q.formula.blank? || (nutrients[q.name].length == ingredients.count)
        completed_q[q.name] = nutrients.delete(q.name)
        next
      end

      if deps.nil? || !deps.empty?
        deps ||= q.formula_quantities
        deps.reject! { |q| completed_q.has_key?(q.name) }
        deps.each { |q| unchecked_q << [q, nil] unless unchecked_q.index { |u| u[0] == q } }
      end

      if deps.empty?
        input_q = q.formula_quantities
        ingredients.each do |i|
          next if !nutrients[q.name][i.id].nil?
          inputs = input_q.map do |i_q|
            default_input = [nil, nil]
            nutrient_data = (completed_q[i_q.name] || nutrients[i_q.name])[i.id]
            [i_q.name, (nutrient_data || [nil, nil])[0]]
          end
          nutrients[q.name][i.id] = q.calculate(inputs)
        end
        unchecked_q.unshift([q, deps])
      else
        unchecked_q << [q, deps]
      end
    end

    all_q = nutrients.merge(completed_q)
    ingredients.map do |i|
      requested_n = requested_q.map { |q| [q.name, all_q[q.name][i.id]] }
      extra_n = extra_q.map { |q_name| [q_name, all_q[q_name][i.id]] if all_q[q_name][i.id] }
      [i, requested_n, extra_n.compact]
    end
  end
end
