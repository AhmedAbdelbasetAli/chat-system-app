# Null object pattern for Redis when unavailable
class NullRedis
  def method_missing(method, *args)
    Rails.logger.warn "Redis not available, ignoring #{method}"
    nil
  end
  
  def respond_to_missing?(method, include_private = false)
    true
  end
  
  def ping
    'PONG' # Fake response for health check
  end
end

# Configure Redis connection
begin
  $redis = Redis.new(
    host: ENV.fetch('REDIS_HOST', 'localhost'),
    port: ENV.fetch('REDIS_PORT', 6379),
    db: ENV.fetch('REDIS_DB', 0),
    timeout: 1
  )
  
  # Test connection
  $redis.ping
  
  # Log Redis connection
  Rails.logger.info "Redis connected successfully"
  
rescue => e
  Rails.logger.error "Failed to connect to Redis: #{e.message}"
  # Create a null Redis object so app doesn't crash
  $redis = NullRedis.new
end
