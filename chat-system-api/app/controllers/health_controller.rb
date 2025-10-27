class HealthController < ApplicationController
  # GET /health
  def index
    # Check database connection
    database_healthy = check_database
    
    # Check Redis connection
    redis_healthy = check_redis
    
    # Overall status
    status = database_healthy && redis_healthy ? 'healthy' : 'unhealthy'
    http_status = database_healthy && redis_healthy ? :ok : :service_unavailable
    
    render json: {
      status: status,
      timestamp: Time.current,
      service: 'chat-system-api',
      checks: {
        database: database_healthy ? 'ok' : 'failed',
        redis: redis_healthy ? 'ok' : 'failed'
      }
    }, status: http_status
  end
  
  private
  
  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue => e
    Rails.logger.error("Database health check failed: #{e.message}")
    false
  end
  
  def check_redis
    $redis.ping == 'PONG'
  rescue => e
    Rails.logger.error("Redis health check failed: #{e.message}")
    false
  end
end
