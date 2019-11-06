class Quantity < ActiveRecord::Base
  require 'ripper'
  QUANTITY_TTYPES = [:on_ident, :on_tstring_content, :on_const]

  enum domain: {
    diet: 0,
    measurement: 1,
    exercise: 2
  }

  acts_as_nested_set dependent: :destroy, scope: :project
  belongs_to :project, required: false

  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :domain, inclusion: {in: domains.keys}
  validate if: -> { parent.present? } do
    errors.add(:parent, :parent_domain_mismatch) unless domain == parent.domain
  end
  validate if: -> { formula.present? } do
    # 1st: check if formula is valid Ruby code
    tokenized_length = Ripper.tokenize(formula).join.length
    unless tokenized_length == formula.length
      errors.add(:formula, :invalid_formula, {part: formula[0...tokenized_length]})
    end

    # 2nd: check if formula contains only allowed token types
    identifiers = []
    Ripper.lex(formula).each do |location, ttype, token|
      case
      when QUANTITY_TTYPES.include?(ttype)
        identifiers << token
      when [:on_sp, :on_int, :on_rational, :on_float, :on_tstring_beg, :on_tstring_end,
        :on_lparen, :on_rparen].include?(ttype)
      when :on_op == ttype && '+-*/'.include?(token)
      else
        errors.add(:formula, :disallowed_token,
                   {token: token, ttype: ttype, location: location})
      end
    end

    # 3rd: check for disallowed function calls (they are not detected by Ripper.lex)
    # FIXME: this is unreliable (?) detection of function calls, should be replaced
    # with parsing Ripper.sexp if necessary
    function = Ripper.slice(formula, 'ident [sp]* lparen')
    errors.add(:formula, :disallowed_function_call, {function: function}) if function

    # 4th: check if identifiers used in formula correspond to existing quantities
    identifiers.uniq!
    quantities = self.project.quantities.where(name: identifiers).pluck(:name)
    if quantities.length != identifiers.length
      errors.add(:formula, :unknown_quantity, {quantities: identifiers - quantities})
    end
  end

  after_initialize do
    if new_record?
      self.primary = false if self.primary.nil?
    end
  end

  def toggle_primary!
    self.toggle!(:primary)
  end

  def formula_quantities
    q_names = Ripper.lex(formula).map do |*, ttype, token|
      token if QUANTITY_TTYPES.include?(ttype)
    end.compact
    self.project.quantities.where(name: q_names).to_a
  end

  def calculate(inputs)
    inputs.map { |i, values| [i, 1.0] }
  end
end
