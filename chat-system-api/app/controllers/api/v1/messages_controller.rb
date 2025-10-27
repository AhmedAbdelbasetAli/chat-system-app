module Api
  module V1
    class MessagesController < BaseController
      before_action :find_application
      before_action :find_chat
      before_action :find_message, only: [:show]
      
      # GET /api/v1/applications/:token/chats/:chat_number/messages
      def index
        @messages = @chat.messages
                         .order(number: :asc)
                         .page(params[:page] || 1)
                         .per(params[:per_page] || 50)
        
        render json: {
          messages: @messages.map { |msg| message_response(msg) },
          pagination: pagination_meta(@messages)
        }
      end
      
      # GET /api/v1/applications/:token/chats/:chat_number/messages/:number
      def show
        render json: message_response(@message)
      end
      
      # POST /api/v1/applications/:token/chats/:chat_number/messages
      def create
        # Get next message number from Redis (atomic - prevents race conditions)
        message_number = RedisCounterService.next_message_number(@chat.id)
        
        @message = @chat.messages.new(
          number: message_number,
          body: params[:body]
        )
        
        if @message.save
          render json: message_response(@message), status: :created
        else
          render json: {
            errors: @message.errors.full_messages,
            status: 422
          }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/applications/:token/chats/:chat_number/messages/search?q=query
      def search
        query = params[:q]
        
        if query.blank?
          render json: {
            error: 'Query parameter required',
            status: 400
          }, status: :bad_request
          return
        end
        
        # Use Elasticsearch (REQUIRED by spec)
        begin
          # Search all messages using Elasticsearch
          response = Message.search_messages(query)
          
          # Filter results to only this chat
          chat_messages = response.records.to_a.select { |msg| msg.chat_id == @chat.id }
          
          render json: {
            results: chat_messages.map { |msg| message_response(msg) },
            query: query,
            total: chat_messages.count,
            search_engine: 'elasticsearch'
          }
        rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
          # Index doesn't exist - need to create it
          render json: {
            error: 'Search index not configured',
            message: 'Run: Message.__elasticsearch__.create_index! force: true',
            details: e.message,
            status: 503
          }, status: :service_unavailable
        rescue => e
          Rails.logger.error("Elasticsearch error: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          
          render json: {
            error: 'Search service error',
            message: e.message,
            status: 503
          }, status: :service_unavailable
        end
      end
      
      private
      
      def find_application
        @application = Application.find_by!(token: params[:application_token] || params[:token])
      end

      def find_chat
        @chat = @application.chats.find_by!(number: params[:chat_number] || params[:chat_chat_number])
      end
      
      def find_message
        @message = @chat.messages.find_by!(number: params[:number])
      end
      
      def message_response(message)
        {
          number: message.number,
          body: message.body,
          created_at: message.created_at,
          updated_at: message.updated_at
        }
      end
    end
  end
end
