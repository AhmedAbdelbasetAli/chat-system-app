# CORS configuration for API access control
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development: allow all origins
    # In production: specify your frontend domain
    origins Rails.env.production? ? ENV.fetch('ALLOWED_ORIGINS', 'https://yourdomain.com').split(',') : '*'
    
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false,
      max_age: 86400
      
    resource '/health',
      headers: :any,
      methods: [:get],
      credentials: false
  end
end
