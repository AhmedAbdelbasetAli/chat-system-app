class UpdateChatCountWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 3
  
  def perform(application_id)
    application = Application.find(application_id)
    
    # Get count from Redis
    redis_key = "app:#{application.token}:chat_counter"
    chat_count = $redis.get(redis_key).to_i
    
    # Update database
    application.update_column(:chats_count, chat_count)
    
    Rails.logger.info "[Worker] Updated chats_count for app #{application.token}: #{chat_count}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[Worker] Application #{application_id} not found: #{e.message}"
  rescue => e
    Rails.logger.error "[Worker] Error updating chat count: #{e.message}"
    raise # Re-raise to trigger Sidekiq retry
  end
end
