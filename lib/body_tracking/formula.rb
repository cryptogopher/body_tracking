module BodyTracking
  module Formula
    require 'ripper'
    QUANTITY_TTYPES = [:on_ident, :on_tstring_content, :on_const]

    class Formula
      def initialize(project, formula)
        @project = project
        @formula = formula
      end

      def validate
        errors = []

        # 1st: check if formula is valid Ruby code
        tokenized_length = Ripper.tokenize(@formula).join.length
        unless tokenized_length == @formula.length
          errors << [:invalid_formula, {part: @formula[0...tokenized_length]}]
        end

        # 2nd: check if formula contains only allowed token types
        identifiers = []
        Ripper.lex(@formula).each do |location, ttype, token|
          case
          when QUANTITY_TTYPES.include?(ttype)
            identifiers << token
          when [:on_sp, :on_int, :on_rational, :on_float, :on_tstring_beg, :on_tstring_end,
                :on_lparen, :on_rparen].include?(ttype)
          when :on_op == ttype &&
            ['+', '-', '*', '/', '%', '**', '==', '!=', '>', '<', '>=', '<=', '<=>', '===',
             '..', '...', '?:', 'and', 'or', 'not', '&&', '||', '!'].include?(token)
          when :on_kw == ttype && ['and', 'or', 'not'].include?(token)
          else
            errors << [:disallowed_token, {token: token, ttype: ttype, location: location}]
          end
        end

        # 3rd: check for disallowed function calls (they are not detected by Ripper.lex)
        # FIXME: this is unreliable (?) detection of function calls, should be replaced
        # with parsing Ripper.sexp if necessary
        function = Ripper.slice(@formula, 'ident [sp]* lparen')
        errors << [:disallowed_function_call, {function: function}] if function

        # 4th: check if identifiers used in formula correspond to existing quantities
        identifiers.uniq!
        quantities = @project.quantities.where(name: identifiers).pluck(:name)
        if quantities.length != identifiers.length
          errors << [:unknown_quantity, {quantities: identifiers - quantities}]
        end

        errors
      end

      def valid?
        self.validate.empty?
      end

      def get_quantities
        q_names = Ripper.lex(@formula).map do |*, ttype, token|
          token if QUANTITY_TTYPES.include?(ttype)
        end.compact
        @project.quantities.where(name: q_names).to_a
      end

      def calculate(inputs)
        paramed_formula = Ripper.lex(@formula).map do |*, ttype, token|
          QUANTITY_TTYPES.include?(ttype) ? "params['#{token}'].to_d" : token
        end.join

        inputs.map do |i, values|
          begin
            [i, get_binding(values).eval(paramed_formula)]
          rescue
            [i, nil]
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
