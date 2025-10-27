class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      # Foreign key to chats table
      t.references :chat, null: false, foreign_key: true
      
      # Message number (unique per chat)
      t.integer :number, null: false
      
      # Message body (text for full-text search)
      t.text :body, null: false

      # Timestamps
      t.timestamps
    end

    # Indexes for performance and uniqueness
    add_index :messages, [:chat_id, :number], unique: true, name: 'index_messages_on_chat_and_number'
    add_index :messages, :created_at
    
    # Full-text search index for MySQL
    execute "ALTER TABLE messages ADD FULLTEXT INDEX idx_messages_body (body)"
  end
end
