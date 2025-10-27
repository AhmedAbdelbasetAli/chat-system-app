# config/initializers/elasticsearch.rb
if defined?(Elasticsearch)
  # Create Elasticsearch index on startup (development only)
  if Rails.env.development?
    begin
      Message.__elasticsearch__.create_index! force: true
      Rails.logger.info "Elasticsearch index created for Message model"
    rescue => e
      Rails.logger.warn "Failed to create Elasticsearch index: #{e.message}"
    end
  end
end
