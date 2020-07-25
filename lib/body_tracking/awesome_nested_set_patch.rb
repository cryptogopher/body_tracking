module BodyTracking::AwesomeNestedSetPatch
  CollectiveIdea::Acts::NestedSet.class_eval do
    module CollectiveIdea::Acts::NestedSet
      class Iterator
        def each_with_ancestors
          return to_enum(__method__) { objects.length } unless block_given?

          ancestors = [nil]
          objects.each do |o|
            ancestors[ancestors.rindex(o.parent)+1..-1] = o
            yield ancestors
          end
        end
      end

      module Model
        module ClassMethods
          def each_with_path(objects)
            return to_enum(__method__, objects) { objects.length } unless block_given?

            Iterator.new(objects).each_with_ancestors do |ancestors|
              yield [ancestors.last, ancestors.map { |q| q.try(:name) }.join('::')]
            end
          end

          def each_with_ancestors(objects)
            return to_enum(__method__, objects) { objects.length } unless block_given?

            Iterator.new(objects).each_with_ancestors { |ancestors| yield ancestors.dup }
          end
        end
      end
    end
  end
end
