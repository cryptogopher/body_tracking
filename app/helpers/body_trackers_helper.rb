module BodyTrackersHelper
  def format_amount(amount, precision=2, mfu_unit=nil)
    value = amount.respond_to?(:value) ? amount.value : amount&.first
    unit = amount.respond_to?(:unit) ? amount.unit : amount&.last

    case
    when value.nil?
      ''
    when value.nan?
      '?'
    else
      value = value.round(precision)
      a_desc = value.nonzero? ? "%.#{precision}f" % value : '-'
      u_desc = unit ? " [#{unit.shortname}]" : ' [-]' if unit != mfu_unit && value.nonzero?
      "#{a_desc}#{u_desc}"
    end
  end

  def format_date(d)
    d&.strftime("%F")
  end

  def format_time(t)
    t&.strftime("%R")
  end

  def format_datetime(dt)
    dt.strftime("%F <small>%R&emsp;(~#{time_ago_in_words(dt)} ago)</small>").html_safe
  end

  def toggle_exposure_options(enabled, domain = :all)
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

  def quantity_options(domain = :except_targets)
    Quantity.each_with_ancestors(@project.quantities.send(domain)).map do |ancestors|
      quantity = ancestors.last
      [
        raw('&ensp;'*(ancestors.length-2) + quantity.name),
        quantity.id,
        {'data-path' => ancestors[1..-2].reduce('::') { |m, q| "#{m}#{q.try(:name)}::" }}
      ]
    end
  end

  # TODO: replace with collection_select and remove
  def unit_options
    @project.units.map do |u|
      [u.shortname, u.id]
    end
  end

  def quantities_table_header(quantities, *fields)
    # spec: table of rows (tr), where each row is a hash of cells (td) (hash keeps items
    # ordered the way they were added). Hash values determine cell property:
    # * int > 0 - quantity name-labelled cell with 'int' size colspan
    # * int < 0 - quantity name-labelled cell with 'int' size rowspan
    # * 0 - non-labelled cell without col-/rowspan
    spec = [Hash.new(0)]
    return spec if quantities.empty?
    default_row = Hash.new(0)

    # Determine colspans first...
    quantities.each do |q|
      ancestors = q.self_and_ancestors.each_with_index do |a, i|
        spec[i] ||= default_row.dup
        spec[i][a] += 1
      end
      spec[ancestors.length...spec.length].each { |row| row[ancestors.last] = 0 }
      default_row[ancestors.last] = 0
    end

    # ...then rowspans
    single_columns = []
    spec[1..-1].each_with_index do |row, i|
      row.each do |q, span|
        # Current span is 0 and previous span == 1
        if (span == 0) && (spec[i][q] == 1)
          spec[i][q] = -(spec.length - i)
          single_columns << q
        end
      end
      single_columns.each { |q| row.delete(q) }
    end

    total_width = fields.length + quantities.length + 1
    table_rows = []
    spec.zip(spec[1..-1]).collect do |row, next_row|
      table_headers = []

      table_headers << fields.collect do |field|
        tag.th(rowspan: spec.length, style: "width: #{100/total_width}%") { l(field) }
      end if row == spec.first

      row.each do |q, span|
        row_attrs = {class: []}
        row_attrs[:class] << 'interim' if (row != spec.last) && (span >= 0)
        row_attrs[:class] << (span == 0 ? 'empty' : 'closable ellipsible')
        row_attrs[:colspan] = span if span > 0
        row_attrs[:rowspan] = -span if span < 0
        row_attrs[:style] = "width: #{[span, 1].max * 100/total_width}%"
        row_attrs[:title] = q.description

        table_headers << tag.th(row_attrs) do
          unless span == 0
            button_class = ['icon']
            if (row == spec.last) || next_row.has_key?(q) || (span < -1)
              button_class << 'icon-close'
            else
              button_class << 'icon-bullet-closed'
            end
            button = tag.div(style: "float:right;position:relative;") do
              link_to '', yield(q.id), {class: button_class, method: :post, remote: true}
            end
            button.html_safe + q.name
          end
        end
      end

      table_headers << tag.th(rowspan: spec.length, style: "width: #{100/total_width}%") do
        l(:field_action)
      end if row == spec.first

      table_rows << tag.tr(class: 'header') { table_headers.join.html_safe }
    end

    tag.thead { table_rows.join.html_safe }
  end
end
