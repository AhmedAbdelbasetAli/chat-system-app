require 'swagger_helper'

RSpec.describe 'api/v1/messages', type: :request do

  path '/api/v1/applications/{application_token}/chats/{chat_number}/messages' do
    parameter name: 'application_token', in: :path, type: :string
    parameter name: 'chat_number', in: :path, type: :integer

    post('Create message') do
      tags 'Messages'
      description 'Creates a new message with sequential numbering'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :message, in: :body, schema: {
        type: :object,
        properties: {
          body: { type: :string, example: 'Hello World!' }
        },
        required: ['body']
      }

      response(201, 'successful') do
        let(:application_token) { create(:application).token }
        let(:chat_number) { 
          app = Application.find_by(token: application_token)
          create(:chat, application: app).number 
        }
        let(:message) { { body: 'Test message' } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'invalid request') do
        let(:application_token) { create(:application).token }
        let(:chat_number) { 
          app = Application.find_by(token: application_token)
          create(:chat, application: app).number 
        }
        let(:message) { { body: '' } }
        run_test!
      end
    end

    get('List messages') do
      tags 'Messages'
      description 'Lists all messages in a chat'
      produces 'application/json'

      response(200, 'successful') do
        let(:application_token) { create(:application).token }
        let(:chat_number) { 
          app = Application.find_by(token: application_token)
          create(:chat, application: app).number 
        }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  path '/api/v1/applications/{application_token}/chats/{chat_number}/messages/search' do
    parameter name: 'application_token', in: :path, type: :string
    parameter name: 'chat_number', in: :path, type: :integer
    parameter name: 'q', in: :query, type: :string, description: 'Search query', required: true

    get('Search messages') do
      tags 'Messages'
      description 'Search messages using Elasticsearch'
      produces 'application/json'

      response(200, 'successful') do
        let(:application_token) { create(:application).token }
        let(:chat_number) { 
          app = Application.find_by(token: application_token)
          create(:chat, application: app).number 
        }
        let(:q) { 'test' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(400, 'bad request') do
        let(:application_token) { create(:application).token }
        let(:chat_number) { 
          app = Application.find_by(token: application_token)
          create(:chat, application: app).number 
        }
        let(:q) { nil }
        run_test!
      end
    end
  end
end
