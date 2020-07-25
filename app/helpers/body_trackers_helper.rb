module BodyTrackersHelper
  def format_value(value, precision=2, mfu_unit=nil)
    amount, unit = value
    case
    when amount.nil?
      '-'
    when amount.nan?
      '?'
    else
      a = amount.round(precision)
      a_desc = a.nonzero? ? "%.#{precision}f" % a : '-'
      u_desc = unit && " [#{unit.shortname}]" || ' [-]' if unit != mfu_unit && a.nonzero?
      "#{a_desc}#{u_desc}"
    end
  end

  def format_time(t)
    t.strftime("%R") if t
  end

  def toggle_exposure_options(enabled, domain)
    enabled = enabled.map { |q| [q.name, q.id] }
    enabled_ids = enabled.map(&:last)

    options = [[t('body_trackers.helpers.exposures_available'), 0]]
    options += nested_set_options(@project.quantities.send(domain)) do |q|
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
    options.collect! { |name, id| [name, enabled_ids.include?(id) ? 0 : id] }

    options = [[t('body_trackers.helpers.exposures_enabled'), 0]] + enabled + options
    options_for_select(options, disabled: 0)
  end

  def quantity_options(domain = :all)
    Quantity.each_with_ancestors(@project.quantities.send(domain)).map do |ancestors|
      quantity = ancestors.last
      [
        raw("#{'&ensp;' * (ancestors.length-2)}#{quantity.name}"),
        quantity.id,
        {'data-path' => ancestors[1..-2].reduce('::') { |m, q| "#{m}#{q.try(:name)}::" }}
      ]
    end
  end

  def unit_options
    @project.units.map do |u|
      [u.shortname, u.id]
    end
  end

  # TODO: rename to quantities_table_header
  def table_header_spec(quantities)
    # spec: table of rows (tr), where each row is a hash of cells (td) (hash keeps items
    # ordered the way they were added). Hash values determine cell property:
    # * int > 0 - quantity name-labelled cell with 'int' size colspan
    # * int < 0 - quantity name-labelled cell with 'int' size rowspan
    # * nil - non-labelled cell without col-/rowspan
    spec = []
    default_row = Hash.new(0)

    # Determine colspans first...
    quantities.each do |q|
      ancestors = q.self_and_ancestors.each_with_index do |a, i|
        spec[i] ||= default_row.dup
        spec[i][a] += 1
      end
      spec[ancestors.length...spec.length].each { |row| row[ancestors.last] = nil }
      default_row[ancestors.last] = nil
    end

    # ...then rowspans
    single_columns = []
    spec[1..-1].each_with_index do |row, i|
      row.each do |q, span|
        # Current span is nil and previous span == 1
        if span.nil? && (spec[i][q] == 1)
          spec[i][q] = -(spec.length - i)
          single_columns << q
        end
      end
      single_columns.each { |q| row.delete(q) }
    end

    spec
  end
end
