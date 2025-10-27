namespace :counters do
  desc "Sync all counter caches from Redis to database"
  task sync: :environment do
    puts "Starting counter synchronization..."
    
    # Update all application chat counts
    Application.find_each do |app|
      UpdateChatCountWorker.perform_async(app.id)
      print "."
    end
    
    puts "\nScheduled #{Application.count} application counter updates"
    
    # Update all chat message counts
    Chat.find_each do |chat|
      UpdateMessageCountWorker.perform_async(chat.id)
      print "."
    end
    
    puts "\nScheduled #{Chat.count} chat counter updates"
    puts "Done! Check Sidekiq dashboard for progress."
  end
end
