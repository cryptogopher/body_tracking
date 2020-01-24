require File.expand_path('../../test_helper', __FILE__)

class FormulaTest < ActiveSupport::TestCase
  include BodyTracking::Formula

  def setup
  end

  def test_builder_parses_valid_formulas_properly
    vector = [
      '4', Set[], [
        {type: :indexed, content: '4*2'}
      ],

      #'4*2'
      #'Fats'
      #'fats'
    ]

    vector.each_slice(3) do |formula, identifiers, parts|
      parser = FormulaBuilder.new(formula)
      i, p = parser.parse
      assert_empty parser.errors
      assert_equal identifiers, i
      assert_equal parts, p
    end
  end
end
