module BodyTracking
  module ApplicationControllerPatch
    ApplicationController.class_eval do
      private

      # :find_* methods are called before :authorize,
      # @project is required for :authorize to succeed
      def find_quantity
        @quantity = Quantity.find(params[:id])
        @project = @quantity.project
      rescue ActiveRecord::RecordNotFound
        render_404
      end
    end
  end
end
