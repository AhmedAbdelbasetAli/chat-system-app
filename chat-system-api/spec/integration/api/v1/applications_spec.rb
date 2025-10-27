require 'swagger_helper'

RSpec.describe 'api/v1/applications', type: :request do

  path '/api/v1/applications' do

    post('Create application') do
      tags 'Applications'
      description 'Creates a new application with a unique token'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :application, in: :body, schema: {
        type: :object,
        properties: {
          name: { 
            type: :string, 
            description: 'Application name',
            example: 'My Chat App' 
          }
        },
        required: ['name']
      }

      response(201, 'successful') do
        let(:application) { { name: 'Test Application' } }

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
        let(:application) { { name: '' } }
        run_test!
      end
    end
  end

  path '/api/v1/applications/{token}' do
    parameter name: 'token', in: :path, type: :string, description: 'Application token'

    get('Show application') do
      tags 'Applications'
      produces 'application/json'
      
      response(200, 'successful') do
        let(:token) { create(:application).token }

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
        let(:token) { 'invalid_token' }
        run_test!
      end
    end

    patch('Update application') do
      tags 'Applications'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :application, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Updated Name' }
        }
      }

      response(200, 'successful') do
        let(:token) { create(:application).token }
        let(:application) { { name: 'Updated Application' } }

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
        let(:token) { 'invalid_token' }
        let(:application) { { name: 'Updated Application' } }
        run_test!
      end
    end
  end
end
