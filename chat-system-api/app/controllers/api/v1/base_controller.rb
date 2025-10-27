module Api
  module V1
    class BaseController < ApplicationController
      # Security headers
      before_action :set_security_headers
      
      # Error handling
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      
      private
      
      def set_security_headers
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains' if Rails.env.production?
      end
      
      def not_found(exception)
        render json: {
          error: 'Not Found',
          message: exception.message,
          status: 404
        }, status: :not_found
      end
      
      def unprocessable_entity(exception)
        render json: {
          error: 'Unprocessable Entity',
          message: exception.message,
          errors: exception.record&.errors&.full_messages,
          status: 422
        }, status: :unprocessable_entity
      end
      
      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          per_page: collection.limit_value,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end
