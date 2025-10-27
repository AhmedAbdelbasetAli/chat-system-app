require 'rails_helper'

RSpec.describe 'Api::V1::Messages', type: :request do
  let!(:application) { create(:application) }
  let!(:chat) { create(:chat, application: application) }
  
  describe 'POST /api/v1/applications/:token/chats/:chat_number/messages' do
    let(:valid_attributes) { { body: 'Hello World' } }
    
    it 'creates a new message' do
      expect {
        post "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages",
             params: valid_attributes, as: :json
      }.to change(Message, :count).by(1)
    end
    
    it 'returns a created status' do
      post "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages",
           params: valid_attributes, as: :json
      expect(response).to have_http_status(:created)
    end
    
    it 'returns the message with a number' do
      post "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages",
           params: valid_attributes, as: :json
      json = JSON.parse(response.body)
      
      expect(json['number']).to be_a(Integer)
      expect(json['number']).to be > 0
      expect(json['body']).to eq('Hello World')
    end
    
    it 'assigns sequential numbers to multiple messages' do
      post "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages",
           params: { body: 'First message' }, as: :json
      first_message = JSON.parse(response.body)
      first_number = first_message['number']
      
      post "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages",
           params: { body: 'Second message' }, as: :json
      second_message = JSON.parse(response.body)
      
      expect(second_message['number']).to eq(first_number + 1)
    end
    
    it 'does not expose the database ID' do
      post "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages",
           params: valid_attributes, as: :json
      json = JSON.parse(response.body)
      
      expect(json).not_to have_key('id')
    end
    
    it 'queues an Elasticsearch indexing job' do
      expect {
        post "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages",
             params: valid_attributes, as: :json
      }.to change(IndexMessageWorker.jobs, :size).by(1)
    end
    
    context 'with invalid parameters' do
      let(:invalid_attributes) { { body: '' } }
      
      it 'does not create a message' do
        expect {
          post "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages",
               params: invalid_attributes, as: :json
        }.not_to change(Message, :count)
      end
      
      it 'returns an unprocessable entity status' do
        post "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages",
             params: invalid_attributes, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe 'GET /api/v1/applications/:token/chats/:chat_number/messages' do
    before do
      # Create messages one by one to ensure proper numbering
      5.times { create(:message, chat: chat) }
    end
    
    it 'returns all messages for the chat' do
      get "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages", as: :json
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json.length).to eq(5)
    end
    
    it 'returns messages ordered by number' do
      get "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages", as: :json
      json = JSON.parse(response.body)
      
      numbers = json.map { |msg| msg['number'] }
      expect(numbers).to eq(numbers.sort)
    end
  end
  
  describe 'GET /api/v1/applications/:token/chats/:chat_number/messages/:number' do
    let!(:message) { create(:message, chat: chat, body: 'Test message') }
    
    context 'when the message exists' do
      it 'returns the message' do
        get "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages/#{message.number}", as: :json
        expect(response).to have_http_status(:ok)
      end
      
      it 'returns message details' do
        get "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages/#{message.number}", as: :json
        json = JSON.parse(response.body)
        
        expect(json['number']).to eq(message.number)
        expect(json['body']).to eq('Test message')
      end
    end
    
    context 'when the message does not exist' do
      it 'returns a not found status' do
        get "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages/999", as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  describe 'GET /api/v1/applications/:token/chats/:chat_number/messages/search' do
    before do
      create(:message, chat: chat, body: 'Hello world from Elasticsearch')
      create(:message, chat: chat, body: 'Another test message')
      create(:message, chat: chat, body: 'Hello again')
      
      # Give Elasticsearch time to index (in real tests, you'd mock this)
      sleep 1
    end
    
    context 'with a matching query' do
      it 'returns matching messages' do
        get "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages/search?q=hello", 
            as: :json
        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json).to have_key('results')
        expect(json['query']).to eq('hello')
      end
    end
    
    context 'without a query parameter' do
      it 'returns a bad request status' do
        get "/api/v1/applications/#{application.token}/chats/#{chat.number}/messages/search", 
            as: :json
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
