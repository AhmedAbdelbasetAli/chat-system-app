class Chat < ApplicationRecord
  # Associations
  belongs_to :application, counter_cache: true
  has_many :messages, dependent: :destroy
  
  # Validations
  validates :number, presence: true, uniqueness: { scope: :application_id }
  validates :application_id, presence: true
  
  # Callbacks - ORDER MATTERS!
  before_validation :set_number, on: :create  
  after_create :initialize_redis_counter
  after_create :schedule_counter_update
  
  private
  
  # Set sequential number for this chat
  def set_number
    return if number.present?
    
    # Get the next number for this application
    last_chat = application.chats.order(number: :desc).first
    self.number = last_chat ? last_chat.number + 1 : 1
    
    Rails.logger.info "[Chat] Assigned number #{self.number} to new chat for application #{application_id}"
  rescue => e
    Rails.logger.error "[Chat] Failed to set number: #{e.message}"
    self.number = 1  # Fallback to 1 if error
  end
  
  def initialize_redis_counter
    # Initialize Redis counter for messages in this chat
    redis_key = "chat:#{self.id}:message_counter"
    $redis.set(redis_key, 0) unless $redis.exists?(redis_key)
    
    Rails.logger.info "[Redis] Initialized message counter for chat #{self.id}"
  rescue => e
    Rails.logger.error "[Redis] Failed to initialize message counter: #{e.message}"
  end
  
  def schedule_counter_update
    # Schedule background job to update application chat count
    UpdateChatCountWorker.perform_in(5.minutes, self.application_id)
  rescue => e
    Rails.logger.error "[Sidekiq] Failed to schedule counter update: #{e.message}"
  end
end
