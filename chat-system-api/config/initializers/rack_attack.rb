# Rate limiting and throttling configuration
class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  
  ### Throttle Spammy Requests ###
  
  # Throttle all requests by IP (60rpm)
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip unless req.path.start_with?('/health')
  end
  
  # Throttle POST requests to /api/ (30rpm per IP)
  throttle('api/ip', limit: 30, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/') && req.post?
  end
  
  # Throttle by application token (100rpm per token)
  throttle('api/token', limit: 100, period: 1.minute) do |req|
    if req.path.start_with?('/api/') && req.post?
      begin
        body = JSON.parse(req.body.read)
        req.body.rewind
        body['application_token'] || body.dig('data', 'attributes', 'application_token')
      rescue JSON::ParserError
        nil
      end
    end
  end
  
  ### Custom Response for Throttled Requests ###
  self.throttled_responder = lambda do |env|
    [
      429,  # HTTP 429 Too Many Requests
      {'Content-Type' => 'application/json'},
      [{
        error: 'Rate limit exceeded',
        message: 'Too many requests. Please try again later.',
        retry_after: 60
      }.to_json]
    ]
  end
  
  ### Allow Localhost in Development ###
  safelist('allow from localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip if Rails.env.development?
  end
end
