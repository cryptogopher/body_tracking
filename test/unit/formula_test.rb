require File.expand_path('../../test_helper', __FILE__)

class FormulaTest < ActiveSupport::TestCase
  include BodyTracking::FormulaBuilder

  def setup
  end

  def test_builder_parses_valid_formulas_properly
    # TODO: add tests
    # failing test vectors:
    # - fcall disallowed: "abs(Fats)+Energy < 10"

    vector = [
      # Non-quantity expressions
      '4', Set[], [
        {type: :indexed, content: "4"}
      ],
      '3.2', Set[], [
        {type: :indexed, content: "3.2"}
      ],
      '4 * 2', Set[], [
        {type: :indexed, content: "4*2"}
      ],
      '7.3 * 2.1', Set[], [
        {type: :indexed, content: "7.3*2.1"}
      ],
      '7 * 2.1', Set[], [
        {type: :indexed, content: "7*2.1"}
      ],

      # Quantity expressions
      'Fats', Set['Fats'], [
        {type: :indexed, content: "quantities['Fats'][_index]"}
      ],
      'fats', Set['fats'], [
        {type: :indexed, content: "quantities['fats'][_index]"}
      ],
      '2 * Fats', Set['Fats'], [
        {type: :indexed, content: "2*quantities['Fats'][_index]"}
      ],
      '4*Proteins + 9*Fats + 4*Carbohydrates', Set['Proteins', 'Fats', 'Carbohydrates'], [
        {type: :indexed, content: "4*quantities['Proteins'][_index]+" \
         "9*quantities['Fats'][_index]+4*quantities['Carbohydrates'][_index]"}
      ],
      'Weight * (Fats + 0.2)', Set['Weight', 'Fats'], [
        {type: :indexed, content: "quantities['Weight'][_index]*" \
         "(quantities['Fats'][_index]+0.2)"}
      ],

      # Numeric method calls
      'Fats.nil?', Set['Fats'], [
        {type: :indexed, content: "quantities['Fats'][_index].nil?"}
      ],
      '((Energy-Calculated)/Energy).abs', Set['Energy', 'Calculated'], [
        {type: :indexed, content: "((quantities['Energy'][_index]-" \
         "quantities['Calculated'][_index])/quantities['Energy'][_index]).abs"}
      ],

      # Conditional expressions
      'Fats.nil? || Fats/Proteins > 2', Set['Fats', 'Proteins'], [
        {type: :indexed, content: "quantities['Fats'][_index].nil?||" \
         "quantities['Fats'][_index]/quantities['Proteins'][_index]>2"}
      ],

      # Model method calls
      '100*Energy/RM.lastBefore(Meal.eaten_at||Meal.created_at)', Set['Energy', 'RM', 'Meal'],
      [
        {type: :indexed, content: "quantities['Meal'][_index].eaten_at||" \
         "quantities['Meal'][_index].created_at"},
        {type: :unindexed, content: "quantities['RM'].lastBefore(parts[0])"},
        {type: :indexed, content: "100*quantities['Energy'][_index]/parts[1][_index]"}
      ],

      # Qualified quantity identifiers
      'Energy::calculated > Energy', Set['Energy::calculated', 'Energy'], [
        {type: :indexed, content: "quantities['Energy::calculated'][_index]>" \
         "quantities['Energy'][_index]"}
      ],
      '"Energy::as %RM" < 100', Set['Energy::as %RM'], [
        {type: :indexed, content: "quantities['Energy::as %RM'][_index]<100"}
      ],
    ]

    d_methods = ['nil?', 'abs']
    q_methods = Hash.new(['all', 'lastBefore'])
    q_methods['Meal'] = ['created_at', 'eaten_at']

    vector.each_slice(3) do |formula, identifiers, parts|
      parser = FormulaBuilder.new(formula, d_methods: d_methods, q_methods: q_methods)
      i, p = parser.parse
      assert_empty parser.errors
      assert_equal identifiers, i
      assert_equal parts, p
    end
  end
end
