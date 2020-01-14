require 'ripper'
require 'pp'
require 'byebug'

class DemoBuilder < Ripper::SexpBuilder
  def initialize(*args)
    super(*args)
    @errors = []
    @identifiers = []
    @arguments = []
  end

  events = private_instance_methods(false).grep(/\Aon_/) {$'.to_sym}
  (PARSER_EVENTS - events).each do |event|
    module_eval(<<-End, __FILE__, __LINE__ + 1)
      def on_#{event}(*args)
        super.tap { |result| p result }
      end
    End
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
      when :quantity
        "params['#{token}']"
      when :indexed_expr
        # FIXME: token expression has to be evaluated in block with _index and
        # result stored in @arguments
        @arguments << token
        "args['#{@arguments.length - 1}']"
      else
        raise NotImplementedError
      end
    end.join(',') <<
    ")"
  end

  #def on_call(left, dot, right)
  #  "#{left}#{dot}#{right}"
  #end
  
  #def on_method_add_arg(method, arg)
  #  "#{method}#{arg}"
  #end

  def on_binary(left, op, right)
    [
      :indexed_expr,
      [left, right].map do |side|
        side[0] == :quantity ? "params['#{side[1]}'][_index]" : "#{side[1]}"
      end.join(op.to_s)
    ]
  end

  def on_var_ref(var_ref)
    ttype, name = var_ref
    if ttype == :quantity_name
      [:quantity, name] 
    else
      raise NotImplementedError
    end
  end

  SCANNER_EVENTS.each do |event|
    module_eval(<<-End, __FILE__, __LINE__ + 1)
      def on_#{event}(tok)
        super.tap { |result| p result }
        #super
      end
    End
  end

  def on_const(token)
    @identifiers << token
    [:quantity_name, token]
  end

  def on_ident(token)
    token
  end
end

#src = "1 + 1"
src = "(Weight/Height.all(3*Dupa).lastBefore(TakenAt)^2) + 2*Other*Other"
#src = "a = 2; b = a"
pp DemoBuilder.new(src).parse
pp Ripper.sexp_raw(src)
