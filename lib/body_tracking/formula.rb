module BodyTracking
  module Formula
    class InvalidFormula < RuntimeError; end
    class Formula
      def initialize(project, formula)
        @project_quantities = Quantity.where(project: project)
        @formula = formula
        @parts = nil
        @quantities = nil
      end

      def validate
        # TODO: add tests
        # failing test vectors:
        # - fcall disallowed: "abs(Fats)+Energy < 10"
        # working test vectors:
        #   ((Energy-Calculated)/Energy).abs > 0.2
        #   Fats.nil? || Fats/Proteins > 2

        parser = FormulaBuilder.new(@formula)
        identifiers, parts = parser.parse
        errors = parser.errors

        quantities = @project_quantities.where(name: identifiers)
        quantities_names = quantities.pluck(:name)
        (identifiers - quantities_names).each do |q|
          errors << [:unknown_quantity, {quantity: q}]
        end

        @parts, @quantities = parts, quantities if errors.empty?
        errors
      end

      def valid?
        @quantities || self.validate.empty?
      end

      def get_quantities
        raise RuntimeError, 'Invalid formula' unless self.valid?

        @quantities.to_a
      end

      #"params.values.first.each_with_index.map { |*, _index| #{@paramed_formula} }"
      def calculate(inputs)
        raise RuntimeError, 'Invalid formula' unless self.valid?

        values = inputs.map { |q, v| [q.name, v.transpose[0]] }.to_h
        puts values.inspect
        begin
          get_binding(values).eval(@paramed_formula).map { |x| [x, nil] }
        rescue Exception => e
          puts e.message
          [[nil, nil]] * inputs.values.first.length
        end
      end

      private

      def get_binding(params)
        binding
      end
    end

    class FormulaValidator < ActiveModel::EachValidator
      def initialize(options)
        super(options)
      end

      def validate_each(record, attribute, value)
        Formula.new(record.project, value).validate.each do |message, params|
          record.errors.add(attribute, message, params)
        end
      end
    end
  end
end
