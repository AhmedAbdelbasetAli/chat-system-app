class Message < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  
  # Associations
  belongs_to :chat, counter_cache: true
  
  # Validations
  validates :number, presence: true, uniqueness: { scope: :chat_id }
  validates :chat_id, presence: true
  validates :body, presence: true, length: { minimum: 1, maximum: 5000 }
  
  # Callbacks - ORDER MATTERS!
  before_validation :set_number, on: :create  # ← ADD THIS FIRST!
  after_create :index_to_elasticsearch_async
  after_create :schedule_counter_update
  
  # Elasticsearch index settings
  settings index: { 
    number_of_shards: 1,
    number_of_replicas: 0
  } do
    mappings dynamic: false do
      indexes :id, type: :integer
      indexes :number, type: :integer
      indexes :body, type: :text, analyzer: :english
      indexes :chat_id, type: :integer
      indexes :created_at, type: :date
    end
  end
  
  # Custom method for Elasticsearch indexing
  def as_indexed_json(options = {})
    {
      id: id,
      number: number,
      body: body,
      chat_id: chat_id,
      created_at: created_at
    }
  end
  
  # Elasticsearch search method
  def self.search_messages(query)
    __elasticsearch__.search({
      query: {
        multi_match: {
          query: query,
          fields: ['body'],
          fuzziness: 'AUTO',
          operator: 'or'
        }
      },
      highlight: {
        fields: {
          body: {
            pre_tags: ['<mark>'],
            post_tags: ['</mark>']
          }
        }
      },
      size: 100
    })
  end
  
  private
  
  # Set sequential number for this message within the chat
  def set_number
    return if number.present?
    
    # Get the next number for this chat
    last_message = chat.messages.order(number: :desc).first
    self.number = last_message ? last_message.number + 1 : 1
    
    Rails.logger.info "[Message] Assigned number #{self.number} to new message in chat #{chat_id}"
  rescue => e
    Rails.logger.error "[Message] Failed to set number: #{e.message}"
    self.number = 1  # Fallback to 1 if error
  end
  
  def index_to_elasticsearch_async
    # Queue background job to index this message
    IndexMessageWorker.perform_async(self.id)
    Rails.logger.info "[Elasticsearch] Queued indexing for message #{self.id}"
  rescue => e
    Rails.logger.error "[Sidekiq] Failed to queue Elasticsearch indexing: #{e.message}"
  end
  
  def schedule_counter_update
    # Schedule background job to update chat message count
    UpdateMessageCountWorker.perform_in(5.minutes, self.chat_id)
    Rails.logger.info "[Sidekiq] Scheduled counter update for chat #{self.chat_id}"
  rescue => e
    Rails.logger.error "[Sidekiq] Failed to schedule counter update: #{e.message}"
  end
end
