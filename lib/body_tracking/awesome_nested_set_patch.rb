module BodyTracking::AwesomeNestedSetPatch
  CollectiveIdea::Acts::NestedSet.class_eval do
    module CollectiveIdea::Acts::NestedSet
      class Iterator
        def each_with_path
          return to_enum(__method__) { objects.length } unless block_given?

          path = [nil]
          objects.each do |o|
            path[path.rindex(o.parent)+1..-1] = o
            yield [o, path.map { |q| q.try(:name) }.join('::')]
          end
        end
      end

      module Model
        module ClassMethods
          def each_with_path(objects, &block)
            Iterator.new(objects).each_with_path(&block)
          end
        end
      end
    end
  end
end
