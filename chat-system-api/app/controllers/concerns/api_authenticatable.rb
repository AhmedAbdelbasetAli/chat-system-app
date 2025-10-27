module ApiAuthenticatable
  extend ActiveSupport::Concern
  
  included do
    before_action :verify_api_key, unless: :health_check?
  end
  
  private
  
  def verify_api_key
    # Skip authentication in development mode (optional)
    return true if Rails.env.development? && ENV['SKIP_API_KEY_CHECK'] == 'true'
    
    api_key = request.headers['X-API-Key']
    
    unless api_key.present? && valid_api_key?(api_key)
      render json: {
        error: 'Unauthorized',
        message: 'Invalid or missing API key. Include X-API-Key header.',
        status: 401
      }, status: :unauthorized
    end
  end
  
  def valid_api_key?(key)
    # In production: store API keys in database with hashing
    # For now: use environment variable
    api_keys = ENV.fetch('API_KEYS', '').split(',')
    api_keys.include?(key) || key == ENV['MASTER_API_KEY']
  end
  
  def health_check?
    controller_name == 'health'
  end
end
