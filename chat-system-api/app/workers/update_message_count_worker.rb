class UpdateMessageCountWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 3
  
  def perform(chat_id)
    chat = Chat.find(chat_id)
    
    # Get count from Redis
    redis_key = "chat:#{chat.id}:message_counter"
    message_count = $redis.get(redis_key).to_i
    
    # Update database
    chat.update_column(:messages_count, message_count)
    
    Rails.logger.info "[Worker] Updated messages_count for chat #{chat.id}: #{message_count}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[Worker] Chat #{chat_id} not found: #{e.message}"
  rescue => e
    Rails.logger.error "[Worker] Error updating message count: #{e.message}"
    raise # Re-raise to trigger Sidekiq retry
  end
end
