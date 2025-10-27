class CreateApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :applications do |t|
      # Token for identifying the application (unique)
      t.string :token, null: false, limit: 255
      
      # Application name
      t.string :name, null: false, limit: 255
      
      # Counter cache for chats
      t.integer :chats_count, default: 0, null: false

      # Timestamps (created_at, updated_at)
      t.timestamps
    end

    # Indexes for performance
    add_index :applications, :token, unique: true
    add_index :applications, :created_at
  end
end
