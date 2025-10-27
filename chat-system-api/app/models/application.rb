class Application < ApplicationRecord
  # Associations
  has_many :chats, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :token, presence: true, uniqueness: true
  
  # Callbacks
  before_validation :generate_token, on: :create
  after_create :initialize_redis_counter
  
  private
  
  def generate_token
    self.token = SecureRandom.hex(10) if token.blank?
  end
  
  def initialize_redis_counter
    # Initialize Redis counter for this application
    redis_key = "app:#{self.token}:chat_counter"
    $redis.set(redis_key, 0) unless $redis.exists(redis_key)
    
    Rails.logger.info "[Redis] Initialized chat counter for app #{self.token}"
  rescue => e
    Rails.logger.error "[Redis] Failed to initialize counter: #{e.message}"
  end
end
