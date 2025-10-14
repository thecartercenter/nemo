# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      # Skip CSRF protection for API
      skip_before_action :verify_authenticity_token
      
      # Use JSON for all responses
      respond_to :json
      
      # Handle API authentication
      before_action :authenticate_api_user!
      
      # Set JSON response format
      before_action :set_json_format
      
      # Handle API errors
      rescue_from StandardError, with: :handle_api_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from CanCan::AccessDenied, with: :handle_access_denied
      
      private
      
      def authenticate_api_user!
        # Try token authentication first
        if api_token.present?
          @current_user = User.find_by(api_key: api_token)
          return if @current_user&.active?
        end
        
        # Fall back to session authentication
        if current_user&.active?
          @current_user = current_user
          return
        end
        
        render json: { error: 'Authentication required' }, status: :unauthorized
      end
      
      def api_token
        request.headers['Authorization']&.gsub(/^Bearer /, '') ||
        params[:api_token] ||
        request.headers['X-API-Token']
      end
      
      def set_json_format
        request.format = :json
      end
      
      def handle_api_error(exception)
        Rails.logger.error "API Error: #{exception.message}"
        Rails.logger.error exception.backtrace.join("\n")
        
        render json: {
          error: 'Internal server error',
          message: Rails.env.development? ? exception.message : 'Something went wrong'
        }, status: :internal_server_error
      end
      
      def handle_not_found(exception)
        render json: {
          error: 'Not found',
          message: 'The requested resource was not found'
        }, status: :not_found
      end
      
      def handle_access_denied(exception)
        render json: {
          error: 'Access denied',
          message: 'You do not have permission to access this resource'
        }, status: :forbidden
      end
      
      def current_user
        @current_user
      end
      
      def current_mission
        @current_mission ||= begin
          if params[:mission_id].present?
            Mission.find(params[:mission_id])
          elsif current_user&.last_mission
            current_user.last_mission
          else
            current_user&.missions&.first
          end
        end
      end
      
      def paginate_params
        {
          page: params[:page] || 1,
          per_page: [params[:per_page]&.to_i || 20, 100].min
        }
      end
      
      def success_response(data = {}, message = 'Success')
        {
          success: true,
          message: message,
          data: data
        }
      end
      
      def error_response(message = 'Error', errors = {})
        {
          success: false,
          message: message,
          errors: errors
        }
      end
    end
  end
end