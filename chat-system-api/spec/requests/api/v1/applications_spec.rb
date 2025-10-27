require 'rails_helper'

RSpec.describe 'Api::V1::Applications', type: :request do
  describe 'POST /api/v1/applications' do
    context 'with valid parameters' do
      let(:valid_attributes) { { name: 'Test Application' } }
      
      it 'creates a new application' do
        expect {
          post '/api/v1/applications', params: valid_attributes, as: :json
        }.to change(Application, :count).by(1)
      end
      
      it 'returns a created status' do
        post '/api/v1/applications', params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
      end
      
      it 'returns the application with a token' do
        post '/api/v1/applications', params: valid_attributes, as: :json
        json = JSON.parse(response.body)
        
        expect(json['name']).to eq('Test Application')
        expect(json['token']).to be_present
        expect(json['token'].length).to eq(20)
        expect(json['chats_count']).to eq(0)
      end
      
      it 'does not expose the database ID' do
        post '/api/v1/applications', params: valid_attributes, as: :json
        json = JSON.parse(response.body)
        
        expect(json).not_to have_key('id')
      end
    end
    
    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '' } }
      
      it 'does not create a new application' do
        expect {
          post '/api/v1/applications', params: invalid_attributes, as: :json
        }.not_to change(Application, :count)
      end
      
      it 'returns an unprocessable entity status' do
        post '/api/v1/applications', params: invalid_attributes, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe 'GET /api/v1/applications/:token' do
    let!(:application) { create(:application) }
    
    context 'when the application exists' do
      it 'returns the application' do
        get "/api/v1/applications/#{application.token}", as: :json
        expect(response).to have_http_status(:ok)
      end
      
      it 'returns application details' do
        get "/api/v1/applications/#{application.token}", as: :json
        json = JSON.parse(response.body)
        
        expect(json['token']).to eq(application.token)
        expect(json['name']).to eq(application.name)
        expect(json['chats_count']).to eq(0)
      end
    end
    
    context 'when the application does not exist' do
      it 'returns a not found status' do
        get '/api/v1/applications/invalid_token', as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  describe 'PATCH /api/v1/applications/:token' do
    let!(:application) { create(:application, name: 'Original Name') }
    
    context 'with valid parameters' do
      let(:new_attributes) { { name: 'Updated Name' } }
      
      it 'updates the application' do
        patch "/api/v1/applications/#{application.token}", 
              params: new_attributes, as: :json
        application.reload
        expect(application.name).to eq('Updated Name')
      end
      
      it 'returns the updated application' do
        patch "/api/v1/applications/#{application.token}", 
              params: new_attributes, as: :json
        json = JSON.parse(response.body)
        
        expect(json['name']).to eq('Updated Name')
        expect(json['token']).to eq(application.token)
      end
    end
    
    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '' } }
      
      it 'does not update the application' do
        original_name = application.name
        patch "/api/v1/applications/#{application.token}", 
              params: invalid_attributes, as: :json
        application.reload
        expect(application.name).to eq(original_name)
      end
      
      it 'returns an unprocessable entity status' do
        patch "/api/v1/applications/#{application.token}", 
              params: invalid_attributes, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
