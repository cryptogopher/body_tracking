module Validations::NestedUniqueness
  extend ActiveSupport::Concern

  included do
    class_attribute :nested_uniqueness_options, instance_writer: false, default: {}
    class_attribute :nested_uniqueness_duplicates, instance_writer: false, default: {}
  end

  module ClassMethods
    def validates_nested_uniqueness_for(*attr_names)
      options = {scope: nil}
      options.update(attr_names.extract_options!)
      options.assert_valid_keys(:scope)

      if association_name = attr_names.shift
        if attr_names.empty?
          raise ArgumentError, "No unique attributes given for name `#{association_name}'."
        else
          options[:attributes] = attr_names

          nested_uniqueness_options = self.nested_uniqueness_options.dup
          nested_uniqueness_options[association_name.to_sym] = options
          self.nested_uniqueness_options = nested_uniqueness_options

          before_validation :before_validation_nested_uniqueness
          after_validation :after_validation_nested_uniqueness

          reflection = reflect_on_association(association_name)
          reflection.klass.class_eval <<-eoruby, __FILE__, __LINE__ + 1
            validate do
              if #{reflection.inverse_of.name}
                   .nested_uniqueness_duplicates[:#{reflection.name}].include?(self)
                errors.add(:base, :duplicated_record) 
              end
            end
          eoruby
        end
      end
    end
  end

  private

  def before_validation_nested_uniqueness
    nested_uniqueness_options.each do |association_name, options|
      collection = send(association_name)
      records = collection.target.dup unless collection.loaded?

      preserved_records = records.select(&:changed?).reject(&:marked_for_destruction?)
      # TODO: do scoping on options[:attributes] and remove options[:scope]
      scope = options[:scope]&.map { |attr| [attr, preserved_records.map(&attr).uniq] }.to_h

      seen = {}
      nested_uniqueness_duplicates[association_name] = []
      collection.where(scope).scoping do
        collection.reject(&:marked_for_destruction?).each do |r|
          key = options[:attributes].map { |attr| r.send(attr) }
          if seen[key]
            nested_uniqueness_duplicates[association_name] << (r.changed? ? r : seen[key])
          else
            seen[key] = r
          end
        end
      end
      if records
        # TODO: reset collction, not proxy
        collection.proxy_association.reset
        records.each { |r| collection.proxy_association.add_to_target(r) }
      end
    end
  end

  def after_validation_nested_uniqueness
    nested_uniqueness_duplicates.clear
  end

  #def before_validation_nested_uniqueness do
  #  was_loaded = targets.loaded?
  #  records = targets.target.select(&:changed?)
  #  dates = records.reject(&:marked_for_destruction?).map(&:effective_from).uniq
  #  seen = {}
  #  @duplicated_records = []
  #  targets.where(effective_from: dates).scoping do
  #    targets.reject(&:marked_for_destruction?).each do |t|
  #      key = [t.effective_from, t.quantity_id, t.item_type, t.item_id, t.scope]
  #      if seen[key]
  #        @duplicated_records << (t.changed? ? t : seen[key])
  #      else
  #        seen[key] = t
  #      end
  #    end
  #  end
  #  unless was_loaded
  #    targets.proxy_association.reset
  #    records.each { |t| targets.proxy_association.add_to_target(t) }
  #  end
  #end

  #def after_validation_nested_uniqueness do
  #  @duplicated_records = nil
  #end
  #def validate_nested_targets_uniqueness(record)
  #  record.errors.add(:base, :duplicated_target) if @duplicated_records.include?(record)
  #end
end
