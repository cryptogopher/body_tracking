require 'ripper'
require 'set'
require 'pp'
require 'byebug'

class DemoBuilder < Ripper::SexpBuilder
  def initialize(*args)
    super(*args)
    @disallowed = Hash.new { |h,k| h[k] = Set.new }
    @identifiers = Set.new
    @paramed_formula = nil
    @arguments = []
  end

  def errors
    @errors = []
    @disallowed[:token].each { |t, e| @errors << [:disallowed_token, {token: t, ttype: e}] }
    @disallowed[:method].each { |f| @errors << [:disallowed_method, {method: f}] }
    @disallowed[:keyword].each { |k| @errors << [:disallowed_keyword, {keyword: k}] }
    @errors
  end

  private

  METHODS = ['abs', 'nil?']

  events = private_instance_methods(false).grep(/\Aon_/) {$'.to_sym}
  (PARSER_EVENTS - events).each do |event|
    module_eval(<<-End, __FILE__, __LINE__ + 1)
      def on_#{event}(*args)
        @disallowed[:token] << [args, '#{event}']
        [:bt_unimplemented, args]
      end
    End
  end

  def on_program(stmts)
    @paramed_formula = join_stmts(stmts)
    [@identifiers, @paramed_formula, @arguments]
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
        "params['#{token}']"
      when :bt_expression
        # FIXME: 'token' expression has to be evaluated in block with _index and
        # result stored in @arguments
        @arguments << token
        "args['#{@arguments.length - 1}']"
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
    [
      :bt_method_call,
      case left[0]
      when :bt_quantity
        "params['#{left[1]}']"
      when :bt_method_call
        "#{left[1]}"
      else
        raise NotImplementedError
      end <<
      dot.to_s <<
      case right[0]
      when :bt_ident
        @disallowed[:method] << right[1] unless METHODS.include?(right[1])
        right[1]
      else
        raise NotImplementedError
      end
    ]
  end

  def on_fcall(token)
    @disallowed[:method] = token[1]
    [:bt_method, token[1]]
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
    [
      :bt_method_call,
      "#{method[1]}#{paren}"
    ]
  end

  def on_binary(left, op, right)
    [
      :bt_expression,
      [left, right].map do |side|
        side[0] == :bt_quantity ? "params['#{side[1]}'][_index]" : "#{side[1]}"
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
        @disallowed[:token] << [token, '#{event}']
        [:bt_unimplemented, token]
      end
    End
  end

  def on_const(token)
    @identifiers << token
    [:bt_quantity, token]
  end

  def on_ident(token)
    [:bt_ident, token]
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
      when :bt_expression
        token
      else
        raise NotImplementedError
      end
    end.join(';')
  end
end

#src = "1 + 1"
src = "(Weight/Height.all(3*Dupa).lastBefore(TakenAt)^2) + 2*Other*'Other'*other"
#src = "a = 2; b = a"
#
pp Ripper.sexp_raw(src)

parser = DemoBuilder.new(src)
pp parser.parse
pp parser.errors
puts "(params['Weight'][_index]/params['Height'].all(args['0']).lastBefore(params['TakenAt'])^2)+2*params['Other'][_index]*params['Other'][_index]*params['other'][_index]"
