Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Health check
  get '/health', to: 'health#index'
  
  # API v1
  namespace :api do
    namespace :v1 do
      # Applications
      resources :applications, param: :token, only: [:create, :show, :update] do
        # Chats
        resources :chats, param: :number, only: [:index, :show, :create] do
          # Messages
          resources :messages, param: :number, only: [:index, :show, :create] do
            # Search
            get 'search', on: :collection
          end
        end
      end
    end
  end
end
