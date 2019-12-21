module BodyTracking
  module ApplicationControllerPatch
    ApplicationController.class_eval do
      private

      def find_quantity(id = :id)
        @quantity = Quantity.find(params[id])
        @project = @quantity.project
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def find_quantity_by_quantity_id
        find_quantity(:quantity_id)
      end
    end
  end
end
