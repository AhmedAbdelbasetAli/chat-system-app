require 'rails_helper'

RSpec.describe 'Api::V1::Chats', type: :request do
  let!(:application) { create(:application) }
  
  describe 'POST /api/v1/applications/:token/chats' do
    it 'creates a new chat' do
      expect {
        post "/api/v1/applications/#{application.token}/chats", as: :json
      }.to change(Chat, :count).by(1)
    end
    
    it 'returns a created status' do
      post "/api/v1/applications/#{application.token}/chats", as: :json
      expect(response).to have_http_status(:created)
    end
    
    it 'returns the chat with a number starting from 1' do
      post "/api/v1/applications/#{application.token}/chats", as: :json
      json = JSON.parse(response.body)
      
      expect(json['number']).to eq(1)
      expect(json['messages_count']).to eq(0)
    end
    
    it 'assigns sequential numbers to multiple chats' do
      post "/api/v1/applications/#{application.token}/chats", as: :json
      first_chat = JSON.parse(response.body)
      
      post "/api/v1/applications/#{application.token}/chats", as: :json
      second_chat = JSON.parse(response.body)
      
      expect(first_chat['number']).to eq(1)
      expect(second_chat['number']).to eq(2)
    end
    
    it 'does not expose the database ID' do
      post "/api/v1/applications/#{application.token}/chats", as: :json
      json = JSON.parse(response.body)
      
      expect(json).not_to have_key('id')
    end
    
    context 'when application does not exist' do
      it 'returns a not found status' do
        post '/api/v1/applications/invalid_token/chats', as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  describe 'GET /api/v1/applications/:token/chats' do
    before do
      # Create chats one by one to ensure proper numbering
      create(:chat, application: application)
      create(:chat, application: application)
      create(:chat, application: application)
    end
    
    it 'returns all chats for the application' do
      get "/api/v1/applications/#{application.token}/chats", as: :json
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      
      # Your API returns direct array
      expect(json.length).to eq(3)
    end
    
    it 'returns chats ordered by number' do
      get "/api/v1/applications/#{application.token}/chats", as: :json
      json = JSON.parse(response.body)
      
      numbers = json.map { |chat| chat['number'] }
      expect(numbers).to eq([1, 2, 3])
    end
  end
  
  describe 'GET /api/v1/applications/:token/chats/:number' do
    let!(:chat) { create(:chat, application: application) }
    
    context 'when the chat exists' do
      it 'returns the chat' do
        get "/api/v1/applications/#{application.token}/chats/#{chat.number}", as: :json
        expect(response).to have_http_status(:ok)
      end
      
      it 'returns chat details' do
        get "/api/v1/applications/#{application.token}/chats/#{chat.number}", as: :json
        json = JSON.parse(response.body)
        
        expect(json['number']).to eq(chat.number)
        expect(json['messages_count']).to eq(0)
      end
    end
    
    context 'when the chat does not exist' do
      it 'returns a not found status' do
        get "/api/v1/applications/#{application.token}/chats/999", as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
