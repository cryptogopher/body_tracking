module BodyTracking
  module Formula
    require 'ripper'
    QUANTITY_TTYPES = [:on_ident, :on_tstring_content, :on_const]
    FUNCTIONS = ['abs', 'nil?']

    class InvalidFormula < RuntimeError; end
    class Formula
      def initialize(project, formula)
        @project = project
        @formula = formula
        @paramed_formula = nil
        @quantities = nil
      end

      def validate
        # TODO: add tests
        # failing test vectors:
        # - fcall disallowed: "abs(Fats)+Energy < 10"
        # working test vectors:
        #   ((Energy-Calculated)/Energy).abs > 0.2
        #   Fats.nil? || Fats/Proteins > 2
        errors = []

        # 1st: check if formula is syntactically valid Ruby code
        begin
          eval("-> { #{@formula} }")
        rescue ScriptError => e
          errors << [:invalid_formula, {msg: e.message}]
        end

        # 2nd: check if formula contains only allowed token types
        # 3rd: check for disallowed function calls
        identifiers = []
        disallowed = Hash.new { |h,k| h[k] = Set.new }

        stree = [Ripper.sexp(@formula)]
        errors << [:unparsable_formula, {}] unless stree.first

        while stree.first
          ttype, token, *rest = stree.shift
          case ttype
          when :program, :args_add_block, :paren
            stree.unshift(*token)
          when :binary
            operator, token2 = rest
            stree.unshift(token, token2)
          when :method_add_arg
            stree.unshift(token, *rest)
          when :call
            stree.unshift(token)
            dot, method = rest
            ftype, fname, floc = method
            disallowed[:function] << fname unless FUNCTIONS.include?(fname)
          when :fcall
            ftype, fname, floc = token
            disallowed[:function] << fname
          when :vcall
            ftype, fname, floc = token
            identifiers << fname
          when :arg_paren
            stree.unshift(token)
          when :var_ref
            vtype, vname, vloc = token
            case vtype
            when :@const
              identifiers << vname
            when :@kw
              disallowed[:keyword] << token if vname != 'nil'
            end
          when :@int, :@float
          else
            errors << [:disallowed_token, {token: token, ttype: ttype}]
          end
        end

        disallowed[:function].each { |f| errors << [:disallowed_function, {function: f}] }
        disallowed[:keyword].each { |k| errors << [:disallowed_keyword, {keyword: k}] }

        # 4th: check if identifiers used in formula correspond to existing quantities
        identifiers.uniq!
        quantities = @project.quantities.where(name: identifiers)
        quantities_names = quantities.pluck(:name)
        (identifiers - quantities_names).each do |q|
          errors << [:unknown_quantity, {quantity: q}]
        end

        if errors.empty?
          @quantities = quantities
          @paramed_formula = Ripper.lex(@formula).map do |*, ttype, token|
            if QUANTITY_TTYPES.include?(ttype) && quantities_names.include?(token)
              "params['#{token}']"
            else
              token
            end
          end.join
        end

        errors
      end

      def valid?
        self.validate if @quantities.nil?
        !@quantities.nil?
      end

      def get_quantities
        raise RuntimeError, 'Invalid formula' unless self.valid?

        @quantities.to_a
      end

      def calculate(inputs)
        raise RuntimeError, 'Invalid formula' unless self.valid?

        inputs.map do |i, values|
          puts values.inspect
          begin
            [i, [get_binding(values).eval(@paramed_formula), nil]]
          rescue Exception => e
            puts e.message
            [i, [nil, nil]]
          end
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
