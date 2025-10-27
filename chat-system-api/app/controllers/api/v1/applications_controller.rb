module Api
  module V1
    class ApplicationsController < BaseController
      before_action :find_application, only: [:show, :update]
      
      # POST /api/v1/applications
      def create
        @application = Application.new(application_params)
        
        if @application.save
          render json: application_response(@application), status: :created
        else
          render json: {
            error: 'Failed to create application',
            details: @application.errors.full_messages,
            status: 422
          }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/applications/:token
      def show
        render json: application_response(@application)
      end
      
      # PUT /api/v1/applications/:token
      def update
        if @application.update(application_params)
          render json: application_response(@application)
        else
          render json: {
            error: 'Failed to update application',
            details: @application.errors.full_messages,
            status: 422
          }, status: :unprocessable_entity
        end
      end
      
      private
      
      def find_application
        @application = Application.find_by!(token: params[:token])
      end
      
      def application_params
        params.require(:application).permit(:name)
      end
      
      def application_response(app)
        {
          token: app.token,
          name: app.name,
          chats_count: app.chats_count,
          created_at: app.created_at,
          updated_at: app.updated_at
        }
      end
    end
  end
end
