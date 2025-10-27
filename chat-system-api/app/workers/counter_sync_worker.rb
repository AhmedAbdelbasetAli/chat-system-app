class CounterSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical
  
  def perform
    Rails.logger.info "[CounterSync] Starting hourly counter sync"
    
    # Queue all application updates
    Application.find_each do |app|
      UpdateChatCountWorker.perform_async(app.id)
    end
    
    # Queue all chat updates
    Chat.find_each do |chat|
      UpdateMessageCountWorker.perform_async(chat.id)
    end
    
    Rails.logger.info "[CounterSync] Queued all counter update jobs"
  end
end
