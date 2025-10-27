module Api
  module V1
    class ChatsController < BaseController
      before_action :find_application
      before_action :find_chat, only: [:show]
      
      # GET /api/v1/applications/:token/chats
      def index
        @chats = @application.chats
                            .order(number: :asc)
                            .page(params[:page] || 1)
                            .per(params[:per_page] || 50)
        
        render json: {
          chats: @chats.map { |chat| chat_response(chat) },
          pagination: pagination_meta(@chats)
        }
      end
      
      # GET /api/v1/applications/:token/chats/:number
      def show
        render json: chat_response(@chat)
      end
      
      # POST /api/v1/applications/:token/chats
      def create
        # Get next chat number from Redis (atomic)
        chat_number = RedisCounterService.next_chat_number(@application.token)
        
        @chat = @application.chats.new(number: chat_number)
        
        if @chat.save
          render json: chat_response(@chat), status: :created
        else
          render json: {
            errors: @chat.errors.full_messages,
            status: 422
          }, status: :unprocessable_entity
        end
      end
      
      private
      
      def find_application
        @application = Application.find_by!(token: params[:application_token] || params[:token])
      end
      
      def find_chat
        @chat = @application.chats.find_by!(number: params[:number])
      end
      
      def chat_response(chat)
        {
          number: chat.number,
          messages_count: chat.messages_count,
          created_at: chat.created_at,
          updated_at: chat.updated_at
        }
      end
    end
  end
end
