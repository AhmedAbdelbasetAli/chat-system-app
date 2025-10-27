class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      # Foreign key to applications table
      t.references :application, null: false, foreign_key: true
      
      # Chat number (unique per application)
      t.integer :number, null: false
      
      # Counter cache for messages
      t.integer :messages_count, default: 0, null: false

      # Timestamps
      t.timestamps
    end

    # Indexes for performance and uniqueness
    add_index :chats, [:application_id, :number], unique: true, name: 'index_chats_on_app_and_number'
    add_index :chats, :created_at
  end
end
