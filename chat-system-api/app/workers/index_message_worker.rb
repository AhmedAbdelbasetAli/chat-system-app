class IndexMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 5
  
  def perform(message_id)
    message = Message.find(message_id)
    
    # Index to Elasticsearch
    message.__elasticsearch__.index_document
    
    Rails.logger.info "[Worker] Indexed message #{message.id} to Elasticsearch"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "[Worker] Message #{message_id} not found, skipping indexing"
  rescue => e
    Rails.logger.error "[Worker] Failed to index message #{message_id}: #{e.message}"
    raise # Re-raise to trigger Sidekiq retry
  end
end
