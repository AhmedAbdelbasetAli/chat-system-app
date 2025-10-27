class RedisCounterService
  class << self
    # Get next chat number for an application
    def next_chat_number(application_token)
      redis_key = "app:#{application_token}:chat_counter"
      
      # Atomic increment and return new value
      next_number = $redis.incr(redis_key)
      
      Rails.logger.info "[Redis] Generated chat number #{next_number} for app #{application_token}"
      next_number
    rescue => e
      Rails.logger.error "[Redis] Error generating chat number: #{e.message}"
      # Fallback to database count + 1
      application = Application.find_by!(token: application_token)
      application.chats.maximum(:number).to_i + 1
    end
    
    # Get next message number for a chat
    def next_message_number(chat_id)
      redis_key = "chat:#{chat_id}:message_counter"
      
      # Atomic increment and return new value
      next_number = $redis.incr(redis_key)
      
      Rails.logger.info "[Redis] Generated message number #{next_number} for chat #{chat_id}"
      next_number
    rescue => e
      Rails.logger.error "[Redis] Error generating message number: #{e.message}"
      # Fallback to database count + 1
      chat = Chat.find(chat_id)
      chat.messages.maximum(:number).to_i + 1
    end
    
    # Sync counter from database to Redis
    def sync_chat_counter(application_token)
      redis_key = "app:#{application_token}:chat_counter"
      application = Application.find_by!(token: application_token)
      
      current_count = application.chats.count
      $redis.set(redis_key, current_count)
      
      Rails.logger.info "[Redis] Synced chat counter for app #{application_token}: #{current_count}"
      current_count
    end
    
    # Sync message counter from database to Redis
    def sync_message_counter(chat_id)
      redis_key = "chat:#{chat_id}:message_counter"
      chat = Chat.find(chat_id)
      
      current_count = chat.messages.count
      $redis.set(redis_key, current_count)
      
      Rails.logger.info "[Redis] Synced message counter for chat #{chat_id}: #{current_count}"
      current_count
    end
  end
end
