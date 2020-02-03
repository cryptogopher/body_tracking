module BodyTracking
  module Formula
    require 'ripper'
    require 'set'

    class InvalidFormula < RuntimeError; end
    class InvalidInputs < RuntimeError; end

    class Formula
      def initialize(project, formula)
        @project = project
        @formula = formula
        @parts = nil
        @quantities = nil
      end

      def validate
        parser = FormulaBuilder.new(@formula)
        identifiers, parts = parser.parse
        errors = parser.errors

        quantities = Quantity.where(project: @project, name: identifiers)
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

      def quantities
        raise(InvalidFormula, 'Invalid formula') unless self.valid?

        @quantities.to_a
      end

      def calculate(inputs)
        quantities = inputs.map { |q, v| [q.name, v.transpose[0]] }.to_h
        length = quantities.values.first.length

        raise(InvalidFormula, 'Invalid formula') unless self.valid?
        raise InvalidInputs unless quantities.values.all? { |v| v.length == length }

        args = []
        @parts.each do |p|
          code = p[:type] == :indexed ?
            "length.times.map { |index| #{p[:content]} }" : p[:content]
          args << get_binding(quantities, args, length).eval(code)
        end
        args.last.map { |v| [v, nil] }
      rescue Exception => e
        puts e.message
        [[nil, nil]] * length
      end

      private

      def get_binding(quantities, args, length)
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


    # List of events with parameter count:
    # https://github.com/racker/ruby-1.9.3-lucid/blob/master/ext/ripper/eventids1.c
    class FormulaBuilder < Ripper::SexpBuilder
      def initialize(*args)
        super(*args)
        @disallowed = Hash.new { |h,k| h[k] = Set.new }
        @identifiers = Set.new
        @parts = []
      end

      def errors
        @errors = []
        @disallowed.each { |k, v| v.each { |e| @errors << ["disallowed_#{k}", {k => e} ] } }
        @errors
      end

      private

      DECIMAL_METHODS = ['abs', 'nil?']
      QUANTITY_METHODS = ['all', 'lastBefore']
      METHODS = DECIMAL_METHODS + QUANTITY_METHODS

      events = private_instance_methods(false).grep(/\Aon_/) {$'.to_sym}
      (PARSER_EVENTS - events).each do |event|
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}(*args)
            @disallowed[:token] << args.to_s + ' [#{event}]'
            [:bt_unimplemented, args]
          end
        End
      end

      def on_parse_error(error)
        @disallowed[:syntax] << error
      end

      def on_program(stmts)
        @parts << {type: :indexed, content: join_stmts(stmts)}
        [@identifiers.to_a, @parts]
      end

      def on_string_content
        ''
      end

      def on_string_add(str, new_str)
        str << new_str
      end

      def on_string_literal(str)
        @identifiers << str
        [:bt_quantity, str]
      end

      def on_args_new
        []
      end

      def on_args_add(args, new_arg)
        args << new_arg
      end

      def on_args_add_block(args, block)
        raise NotImplementedError if block
        args
      end

      def on_arg_paren(args)
        "(" <<
        args.map do |arg|
          ttype, token = arg
          case ttype
          when :bt_quantity
            "quantities['#{token}']"
          when :bt_expression
            @parts << {type: :indexed, content: token}
            "parts[#{@parts.length - 1}]"
          else
            raise NotImplementedError
          end
        end.join(',') <<
        ")"
      end

      def on_stmts_new
        []
      end

      def on_stmts_add(stmts, new_stmt)
        stmts << new_stmt
      end

      def on_paren(stmts)
        [
          :bt_expression,
          "(" << join_stmts(stmts) << ")"
        ]
      end

      def on_call(left, dot, right)
        method, mtype =
          case right[0]
          when :bt_ident
            case
            when DECIMAL_METHODS.include?(right[1])
              [right[1], :numeric_method]
            when QUANTITY_METHODS.include?(right[1])
              [right[1], :quantity_method]
            else
              @disallowed[:method] << right[1]
              [right[1], :unknown_method]
            end
          else
            raise NotImplementedError, right.inspect
          end

        case left[0]
        when :bt_quantity
          if mtype == :quantity_method
            part_index = @parts.length
            @parts << {type: :unindexed,
                       content: "quantities['#{left[1]}']#{dot.to_s}#{method}"}
            [:bt_quantity_method_call, "parts[#{part_index}]", part_index]
          else
            [:bt_numeric_method_call, "quantities['#{left[1]}'][index]#{dot.to_s}#{method}"]
          end
        when :bt_quantity_method_call
          if mtype == :quantity_method
            @parts[left[2]][:content] << "#{dot.to_s}#{method}"
            left
          else
            [:bt_numeric_method_call, "#{left[1]}#{dot.to_s}#{method}"]
          end
        when :bt_numeric_method_call, :bt_expression
          if mtype == :quantity_method
            # TODO: add error reporting
            raise NotImplementedError
          else
            [:bt_numeric_method_call, "#{left[1]}#{dot.to_s}#{method}"]
          end
        else
          raise NotImplementedError, left.inspect
        end
      end

      def on_fcall(token)
        @disallowed[:method] = token[1]
        [:bt_numeric_method_call, token[1]]
      end

      def on_vcall(token)
        case token[0]
        when :bt_ident
          @identifiers << token[1]
          [:bt_quantity, token[1]]
        else
          raise NotImplementedError
        end
      end

      def on_method_add_arg(method, paren)
        case method[0]
        when :bt_quantity_method_call
          @parts[method[2]][:content] << paren
          method
        when :bt_numeric_method_call
          [:bt_numeric_method_call, "#{method[1]}#{paren}"]
        else
          raise NotImplementedError
        end
      end

      def on_binary(left, op, right)
        [
          :bt_expression,
          [left, right].map do |side|
            side[0] == :bt_quantity ? "quantities['#{side[1]}'][index]" : "#{side[1]}"
          end.join(op.to_s)
        ]
      end

      def on_var_ref(var_ref)
        var_ref[0] == :bt_quantity ? var_ref : raise(NotImplementedError)
      end

      silenced_events = [:lparen, :rparen, :op, :period, :sp, :int, :float,
                         :tstring_beg, :tstring_end]
      (SCANNER_EVENTS - silenced_events).each do |event|
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}(token)
            @disallowed[:token] << token + ' [#{event}]'
            [:bt_unimplemented, token]
          end
        End
      end

      def on_const(token)
        @identifiers << token
        [:bt_quantity, token]
      end

      def on_float(token)
        [:bt_expression, token]
      end

      def on_ident(token)
        [:bt_ident, token]
      end

      def on_int(token)
        [:bt_expression, token]
      end

      def on_kw(token)
        @disallowed[:keyword] << token unless token == 'nil'
      end

      def on_tstring_content(token)
        token
      end

      def join_stmts(stmts)
        stmts.map do |stmt|
          ttype, token = stmt
          case ttype
          when :bt_expression, :bt_numeric_method_call
            token
          when :bt_quantity
            "quantities['#{token}'][index]"
          else
            raise NotImplementedError, stmt.inspect
          end
        end.join(';')
      end
    end
  end
end
