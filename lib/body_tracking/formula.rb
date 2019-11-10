module BodyTracking
  module Formula
    require 'ripper'
    QUANTITY_TTYPES = [:on_ident, :on_tstring_content, :on_const]
    FUNCTIONS = ['abs', 'nil?']

    class Formula
      def initialize(project, formula)
        @project = project
        @formula = formula
      end

      #def validate
      #  errors = []

      #  # 1st: check if formula is valid Ruby code
      #  #tokenized_length = Ripper.tokenize(@formula).join.length
      #  #unless tokenized_length == @formula.length
      #  #  errors << [:invalid_formula, {part: @formula[0...tokenized_length]}]
      #  #end
      #  begin
      #    eval("-> { #{@formula} }")
      #  rescue ScriptError => e
      #    errors << [:invalid_formula, {msg: e.message}]
      #  end

      #  # 2nd: check if formula contains only allowed token types
      #  # 3rd: check for disallowed function calls (they are not detected by Ripper.lex)
      #  # FIXME: this is unreliable (?) detection of function calls, should be replaced
      #  # with parsing Ripper.sexp if necessary
      #  identifiers = []
      #  disallowed_functions = Set.new
      #  prev_ttype, prev_token = nil, nil
      #  Ripper.lex(@formula).each do |location, ttype, token|
      #    puts ttype, token
      #    case
      #    when QUANTITY_TTYPES.include?(prev_ttype) && ttype == :on_lparen
      #      disallowed_functions << prev_token unless FUNCTIONS.include?(prev_token)
      #      identifiers -= [prev_token]
      #    when prev_ttype == :on_period && QUANTITY_TTYPES.include?(ttype)
      #      disallowed_functions << token unless FUNCTIONS.include?(token)
      #    when is_token_quantity?(ttype, token)
      #      identifiers << token
      #    when [:on_sp, :on_int, :on_rational, :on_float, :on_tstring_beg, :on_tstring_end,
      #          :on_lparen, :on_rparen, :on_period].include?(ttype)
      #    when :on_op == ttype &&
      #      ['+', '-', '*', '/', '%', '**', '==', '!=', '>', '<', '>=', '<=', '<=>', '===',
      #       '..', '...', '?:', 'and', 'or', 'not', '&&', '||', '!'].include?(token)
      #    when :on_kw == ttype && ['and', 'or', 'not'].include?(token)
      #    else
      #      errors << [:disallowed_token, {token: token, ttype: ttype, location: location}]
      #    end
      #    prev_ttype, prev_token = ttype, token unless ttype == :on_sp
      #  end
      #  disallowed_functions.each { |f| errors << [:disallowed_function_call, {function: f}] }

      #  # 4th: check if identifiers used in formula correspond to existing quantities
      #  identifiers.uniq!
      #  quantities = @project.quantities.where(name: identifiers).pluck(:name)
      #  (identifiers - quantities).each { |q| errors << [:unknown_quantity, {quantity: q}] }

      #  errors
      #end

      def validate
        errors = []

        # 1st: check if formula is valid Ruby code
        #tokenized_length = Ripper.tokenize(@formula).join.length
        #unless tokenized_length == @formula.length
        #  errors << [:invalid_formula, {part: @formula[0...tokenized_length]}]
        #end
        begin
          eval("-> { #{@formula} }")
        rescue ScriptError => e
          errors << [:invalid_formula, {msg: e.message}]
        end

        # 2nd: check if formula contains only allowed token types
        # 3rd: check for disallowed function calls (they are not detected by Ripper.lex)
        # FIXME: this is unreliable (?) detection of function calls, should be replaced
        # with parsing Ripper.sexp if necessary
        # failing test vectors:
        # - fcall disallowed: "abs(Fats)+Energy < 10"
        # working test vectors:
        #   a.abs(Fats)+Energy < 10
        identifiers = []
        disallowed_functions = Set.new

        stree = [Ripper.sexp(@formula)]
        errors << [:unparsable_formula, {}] unless stree.first

        while stree.first
          ttype, token, *rest = stree.shift
          case ttype
          when :program, :args_add_block
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
            disallowed_functions << fname unless FUNCTIONS.include?(fname)
          when :fcall
            ftype, fname, floc = token
            disallowed_functions << fname
          when :vcall
            ftype, fname, floc = token
            identifiers << fname
          when :arg_paren
            stree.unshift(token)
          when :var_ref
            vtype, vname, vloc = token
            identifiers << vname
          when :@int
          else
            errors << [:disallowed_token, {token: token, ttype: ttype}]
          end
        end

        #Ripper.lex(@formula).each do |location, ttype, token|
        #  puts ttype, token
        #  case
        #  when QUANTITY_TTYPES.include?(prev_ttype) && ttype == :on_lparen
        #    disallowed_functions << prev_token unless FUNCTIONS.include?(prev_token)
        #    identifiers -= [prev_token]
        #  when prev_ttype == :on_period && QUANTITY_TTYPES.include?(ttype)
        #    disallowed_functions << token unless FUNCTIONS.include?(token)
        #  when is_token_quantity?(ttype, token)
        #    identifiers << token
        #  when [:on_sp, :on_int, :on_rational, :on_float, :on_tstring_beg, :on_tstring_end,
        #        :on_lparen, :on_rparen, :on_period].include?(ttype)
        #  when :on_op == ttype &&
        #    ['+', '-', '*', '/', '%', '**', '==', '!=', '>', '<', '>=', '<=', '<=>', '===',
        #     '..', '...', '?:', 'and', 'or', 'not', '&&', '||', '!'].include?(token)
        #  when :on_kw == ttype && ['and', 'or', 'not'].include?(token)
        #  else
        #    errors << [:disallowed_token, {token: token, ttype: ttype, location: location}]
        #  end
        #  prev_ttype, prev_token = ttype, token unless ttype == :on_sp
        #end
        disallowed_functions.each { |f| errors << [:disallowed_function_call, {function: f}] }

        # 4th: check if identifiers used in formula correspond to existing quantities
        identifiers.uniq!
        quantities = @project.quantities.where(name: identifiers).pluck(:name)
        (identifiers - quantities).each { |q| errors << [:unknown_quantity, {quantity: q}] }

        errors
      end

      def valid?
        self.validate.empty?
      end

      def get_quantities
        q_names = Ripper.lex(@formula).map do |*, ttype, token|
          token if is_token_quantity?(ttype, token)
        end.compact
        @project.quantities.where(name: q_names).to_a
      end

      def calculate(inputs)
        paramed_formula = Ripper.lex(@formula).map do |*, ttype, token|
          is_token_quantity?(ttype, token) ? "params['#{token}'].to_d" : token
        end.join

        inputs.map do |i, values|
          begin
            [i, [get_binding(values).eval(paramed_formula), nil]]
          rescue Exception => e
            puts e.message
            [i, [nil, nil]]
          end
        end
      end

      private

      def is_token_quantity?(ttype, token)
        QUANTITY_TTYPES.include?(ttype) && !FUNCTIONS.include?(token)
      end

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
