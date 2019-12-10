class Measurement < ActiveRecord::Base
  belongs_to :project, required: true
  belongs_to :source, required: false

  has_many :readouts, inverse_of: :measurement, dependent: :destroy, validate: true
  validates :readouts, presence: true
  accepts_nested_attributes_for :readouts, allow_destroy: true, reject_if: proc { |attrs|
    attrs['quantity_id'].blank? && attrs['value'].blank?
  }
  # Readout quantity_id + unit_id uniqueness validation. Cannot be effectively
  # checked on Readout model level.
  validate do
    quantities = self.readouts.map do |r|
      [r.quantity_id, r.unit_id] unless r.marked_for_destruction?
    end
    if quantities.length != quantities.uniq.length
      errors.add(:readouts, :duplicated_quantity_unit_pair)
    end
  end

  validates :name, presence: true
  validates :taken_at, presence: true

  after_initialize do
    if new_record?
      self.hidden = false if self.hidden.nil?
      self.taken_at = Time.now
    end
  end

  def toggle_hidden!
    self.toggle!(:hidden)
  end

  def taken_at_date
    self.taken_at.getlocal
  end
  def taken_at_date=(value)
    self.taken_at = Time.parse(value, self.taken_at)
  end

  def taken_at_time
    self.taken_at.getlocal
  end
  def taken_at_time=(value)
    self.taken_at = Time.parse(value, self.taken_at)
  end

  def self.filter(filters, requested_q = Quantity.none)
    measurements = all.where(filters[:scope])

    if filters[:name].present?
      measurements = measurements.where("name LIKE ?", "%#{filters[:name]}%")
    end

    project = proxy_association.owner
    formula_q = if filters[:readouts].present?
                  project.quantities.new(name: '__internal_q',
                                         formula: filters[:readouts],
                                         domain: :measurement)
                end
    apply_formula = formula_q.present? && formula_q.valid?

    result =
      if !requested_q.empty? || apply_formula
        computed = measurements.compute_nutrients(requested_q, apply_formula && formula_q)
        requested_q.present? ? computed : [computed[0]]
      else
        [measurements]
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
              nutrient_data = completed_q[i_q.name][i.id] || [nil, nil]
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
      filter_q ? ingredients.to_a.keep_if { |i| all_q[filter_q.name][i.id][0] } : ingredients,
      ingredients.map { |i| requested_q.map { |q| [q.name, all_q[q.name][i.id]] } },
      ingredients.map do |i|
        extra_q.map { |q_name| [q_name, all_q[q_name][i.id]] if all_q[q_name][i.id] }
      end
    ]
  end
end
