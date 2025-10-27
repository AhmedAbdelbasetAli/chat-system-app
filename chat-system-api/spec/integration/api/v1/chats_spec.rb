require 'swagger_helper'

RSpec.describe 'api/v1/chats', type: :request do

  path '/api/v1/applications/{application_token}/chats' do
    parameter name: 'application_token', in: :path, type: :string, description: 'Application token'

    post('Create chat') do
      tags 'Chats'
      description 'Creates a new chat with sequential numbering'
      produces 'application/json'

      response(201, 'successful') do
        let(:application_token) { create(:application).token }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(404, 'application not found') do
        let(:application_token) { 'invalid_token' }
        run_test!
      end
    end

    get('List chats') do
      tags 'Chats'
      description 'Lists all chats for an application'
      produces 'application/json'

      response(200, 'successful') do
        let(:application_token) { create(:application).token }

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

  path '/api/v1/applications/{application_token}/chats/{number}' do
    parameter name: 'application_token', in: :path, type: :string, description: 'Application token'
    parameter name: 'number', in: :path, type: :integer, description: 'Chat number'

    get('Show chat') do
      tags 'Chats'
      produces 'application/json'

      response(200, 'successful') do
        let(:application_token) { create(:application).token }
        let(:number) { 
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

      response(404, 'not found') do
        let(:application_token) { create(:application).token }
        let(:number) { 999 }
        run_test!
      end
    end
  end
end
