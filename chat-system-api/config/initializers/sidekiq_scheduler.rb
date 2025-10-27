# Schedule counter sync every hour (satisfies 1-hour lag requirement)
if defined?(Sidekiq::Scheduler)
  Sidekiq.configure_server do |config|
    config.on(:startup) do
      Sidekiq.schedule = {
        'counter_sync' => {
          'cron' => '0 * * * *',  # Every hour
          'class' => 'CounterSyncWorker',
          'queue' => 'critical'
        }
      }
      Sidekiq::Scheduler.reload_schedule!
    end
  end
end
