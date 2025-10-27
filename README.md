
# Chat System App

A scalable, high-performance chat application built with Ruby on Rails and Golang microservices architecture.

## Overview

This system provides a robust API platform for managing chat applications with full-text search capabilities. It leverages microservices architecture to separate concerns between Rails (business logic, search) and Golang (high-throughput message processing).

### Key Features

- **Token-based Authentication**: Applications identified by system-generated tokens
- **Sequential Numbering**: Race-condition-free chat and message numbering
- **Elasticsearch Integration**: Full-text search with partial matching
- **Background Processing**: Sidekiq for asynchronous operations
- **Optimized Performance**: Redis caching and distributed locking
- **Containerized Deployment**: One-command Docker setup
- **RESTful API**: Complete CRUD operations with Swagger documentation


 ## Architecture

### Technology Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| Ruby on Rails | 7.1.5 | Primary API and business logic |
| Golang | 1.24 | Message creation service |
| MySQL | 8.0 | Relational database |
| Redis | 7.4 | Caching and job queue |
| Elasticsearch | 8.11 | Full-text search engine |
| Sidekiq | Latest | Background job processing |
| Docker | 20.10+ | Containerization |

### Service Architecture

```
┌─────────────────────────────────────────────────────────┐
│                       Client                            │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │                                   │
┌───────▼────────┐                 ┌────────▼──────────┐
│  Rails API     │                 │  Golang Service   │
│  (Port 3000)   │                 │  (Port 8080)      │
│                │                 │                   │
│ - Applications │                 │ - Chat Creation   │
│ - Chats List   │                 │ - Message Creation│
│ - Messages List│                 │ - Redis Locking   │
│ - Search       │                 │                   │
└────────┬───────┘                 └────────┬──────────┘
         │                                  │
         └─────────┬────────────────────────┘
                   │
    ┌──────────────┼──────────────────┐
    │              │                  │
┌───▼────┐   ┌────▼─────┐   ┌────────▼────────┐
│ MySQL  │   │  Redis   │   │ Elasticsearch   │
│ :3307  │   │  :6379   │   │ :9200           │
└────────┘   └──────────┘   └─────────────────┘
```

### Service Endpoints

- **Rails API**: http://localhost:3000
- **Golang Service**: http://localhost:8080
- **MySQL**: localhost:3307
- **Redis**: localhost:6379
- **Elasticsearch**: http://localhost:9200
- **Swagger UI**: http://localhost:3000/api-docs

## Security

### Authentication
- **API Key Authentication**: Golang endpoints require `X-API-Key` header
- **Token-Based Access**: Applications identified by system-generated tokens (no exposed IDs)
- **Development Key**: `dev_key_for_testing_only` (⚠️ Change for production)

### Data Protection
- **SQL Injection Prevention**: All queries use parameterized statements (ActiveRecord, prepared statements)
- **Input Validation**: Character limits enforced, UTF-8 encoding, sanitized inputs
- **Race Condition Protection**: Redis distributed locks ensure data consistency and prevent duplicate numbering

### Configuration Security
- **Environment Variables**: Sensitive credentials stored in environment variables (never committed to Git)
- **CORS**: Configured in `config/initializers/cors.rb` (⚠️ Restrict origins in production)

## Prerequisites

Before installation, ensure you have:

- Docker Desktop 
- Docker Compose 
  
### Verify Docker Installation

```
docker --version
docker-compose --version
docker ps
```

## Installation

### 1. Clone Repository

```
git clone https://github.com/AhmedAbdelbasetAli/chat-system-app.git
cd chat-system-app
```

### 2. Start Services

```
docker-compose up
```

**First-time startup takes 7-10 minutes** as services initialize and databases are created.

### 3. Verify Services

```
# Test Rails API
curl http://localhost:3000/health
# Expected: {"status":"ok"}

# Test Golang Service  
curl http://localhost:8080/health
# Expected: {"status":"ok","service":"golang-chat-service"}
```

### 4. Configure Elasticsearch (Required)

```
docker exec -it chat-system-rails bundle exec rails runner \
  'Message.__elasticsearch__.create_index! force: true'
```

This creates the search index. Run once after first startup.

## API Documentation

### Interactive Documentation

Visit Swagger UI: http://localhost:3000/api-docs




### Application Management

#### Create Application

```
curl -X POST http://localhost:3000/api/v1/applications \
  -H "Content-Type: application/json" \
  -d '{"name": "My Application"}'
```

**Response:**
```
{
  "token": "abc123def456",
  "name": "My Application",
  "chats_count": 0,
  "created_at": "2025-10-27T10:00:00.000Z"
}
```

**Important:** Save the `token` for subsequent operations.

#### Get Application

```
curl http://localhost:3000/api/v1/applications/{token}
```

#### Update Application

```
curl -X PUT http://localhost:3000/api/v1/applications/{token} \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Name"}'
```

#### List Applications

```
curl http://localhost:3000/api/v1/applications
```

### Chat Management

#### Create Chat

```
curl -X POST http://localhost:8080/api/v1/chats \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev_key_for_testing_only" \
  -d '{"application_token":"{token}"}'
```

**Response:**
```
{
  "number": 1,
  "messages_count": 0,
  "created_at": "2025-10-27T10:05:00.000Z"
}
```

Chat numbers are sequential per application (1, 2, 3...).

#### Get Chat

```
curl http://localhost:3000/api/v1/applications/{token}/chats/{number}
```

#### List Chats

```
curl http://localhost:3000/api/v1/applications/{token}/chats
```

### Message Management

#### Create Message

```
curl -X POST http://localhost:8080/api/v1/messages \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev_key_for_testing_only" \
  -d '{
    "application_token": "{token}",
    "chat_number": 1,
    "body": "Hello World!"
  }'
```

**Response:**
```
{
  "number": 1,
  "body": "Hello World!",
  "created_at": "2025-10-27T10:10:00.000Z"
}
```

Message numbers are sequential per chat (1, 2, 3...).

#### Get Message

```
curl http://localhost:3000/api/v1/applications/{token}/chats/1/messages/1
```

#### List Messages

```
curl http://localhost:3000/api/v1/applications/{token}/chats/1/messages
```


### Message Search

```
curl "http://localhost:3000/api/v1/applications/{token}/chats/1/messages/search?q=keyword"
```

**Response:**
```
{
  "results": [
    {
      "number": 1,
      "body": "Message containing keyword",
      "created_at": "2025-10-27T10:10:00.000Z"
    }
  ],
  "query": "keyword",
  "total": 1
}
```

**Search Features:**
- Case-insensitive
- Partial word matching
- Relevance ranking
- Wait 5-10 seconds after message creation for indexing

## Complete Testing Guide

Run this comprehensive test to verify all functionality:

```
# 1. Create application
APP_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/applications \
  -H "Content-Type: application/json" \
  -d '{"name":"Test App"}')

echo "Application created: $APP_RESPONSE"

# Extract token
TOKEN=$(echo $APP_RESPONSE | grep -o '"token":"[^"]*' | grep -o '[^"]*$')
echo "Token: $TOKEN"

# 2. Create chat
echo "Creating chat..."
curl -X POST http://localhost:8080/api/v1/chats \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev_key_for_testing_only" \
  -d "{\"application_token\":\"$TOKEN\"}"

# 3. Create messages
echo "Creating messages..."
curl -X POST http://localhost:8080/api/v1/messages \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev_key_for_testing_only" \
  -d "{\"application_token\":\"$TOKEN\",\"chat_number\":1,\"body\":\"Hello World\"}"

curl -X POST http://localhost:8080/api/v1/messages \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev_key_for_testing_only" \
  -d "{\"application_token\":\"$TOKEN\",\"chat_number\":1,\"body\":\"Testing Docker\"}"

curl -X POST http://localhost:8080/api/v1/messages \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev_key_for_testing_only" \
  -d "{\"application_token\":\"$TOKEN\",\"chat_number\":1,\"body\":\"Elasticsearch search\"}"

# 4. List messages
echo "Listing messages..."
curl http://localhost:3000/api/v1/applications/$TOKEN/chats/1/messages

# 5. Verify counters
echo "Checking counters..."
curl http://localhost:3000/api/v1/applications/$TOKEN
# Should show chats_count: 1

curl http://localhost:3000/api/v1/applications/$TOKEN/chats/1
# Should show messages_count: 3

# 6. Wait for Elasticsearch indexing
echo "Waiting for search indexing..."
sleep 10

# 7. Test search
echo "Testing search..."
curl "http://localhost:3000/api/v1/applications/$TOKEN/chats/1/messages/search?q=docker"
curl "http://localhost:3000/api/v1/applications/$TOKEN/chats/1/messages/search?q=elasticsearch"

echo "✅ Tests completed!"
```

## Database Schema

### Applications Table

```
CREATE TABLE applications (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  token VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  chats_count INT DEFAULT 0,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_token (token)
);
```

### Chats Table

```
CREATE TABLE chats (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  application_id BIGINT NOT NULL,
  number INT NOT NULL,
  messages_count INT DEFAULT 0,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (application_id) REFERENCES applications(id),
  UNIQUE KEY unique_chat_number (application_id, number),
  INDEX idx_application_number (application_id, number)
);
```

### Messages Table

```
CREATE TABLE messages (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  chat_id BIGINT NOT NULL,
  number INT NOT NULL,
  body TEXT NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (chat_id) REFERENCES chats(id),
  UNIQUE KEY unique_message_number (chat_id, number),
  INDEX idx_chat_number (chat_id, number),
  FULLTEXT INDEX idx_body (body)
);
`````

## Race Condition Handling

The system uses Redis distributed locks to prevent race conditions during concurrent operations:

### Chat Number Generation

```
# Redis lock ensures sequential numbering
redis.lock("lock:chat_number:#{application_id}") do
  next_number = redis.incr("chat_number:#{application_id}")
  Chat.create!(application_id: app_id, number: next_number)
end
```

### Message Number Generation

```
# Redis lock prevents duplicate message numbers
redis.lock("lock:message_number:#{chat_id}") do
  next_number = redis.incr("message_number:#{chat_id}")
  Message.create!(chat_id: chat_id, number: next_number, body: body)
end
```

### Testing Race Conditions

```
# Run concurrent requests to verify no duplicates
for i in {1..20}; do
  curl -X POST http://localhost:8080/api/v1/messages \
    -H "Content-Type: application/json" \
    -H "X-API-Key: dev_key_for_testing_only" \
    -d "{\"application_token\":\"$TOKEN\",\"chat_number\":1,\"body\":\"Concurrent $i\"}" &
done

wait

# Verify sequential numbering
curl http://localhost:3000/api/v1/applications/$TOKEN/chats/1/messages | grep -o '"number":[0-9]*' | sort
```

## Elasticsearch Configuration

### Index Creation

```
docker exec -it chat-system-rails bundle exec rails runner \
  'Message.__elasticsearch__.create_index! force: true'
```

### Reindex Existing Messages

```
docker exec -it chat-system-rails bundle exec rails runner \
  'Message.import force: true'
```

### Verify Index

```
# Check index exists
curl http://localhost:9200/messages

# View index mapping
curl http://localhost:9200/messages/_mapping

# Check document count
curl http://localhost:9200/messages/_count
```

## Testing & Specs 

### RSpec Test Suite

This project includes comprehensive RSpec tests

**Test Structure:**
```
spec/
├── models/          # Application, Chat, Message validations
├── requests/        # API endpoint tests
└── factories/       # Test data generation
```

**Run Tests:**
```
docker exec -it chat-system-rails bundle exec rspec
```

**Test Coverage:**
- ✅ Model validations (12 tests)
- ✅ API endpoints (15 tests)
- ✅ Sequential numbering (8 tests)
- ✅ Race conditions (5 tests)
- ✅ Counter updates (6 tests)
- ✅ Search functionality (4 tests)

**Total: 50+ tests, all passing**

### Key Test Examples

**Model Spec:**
```
# spec/models/application_spec.rb
RSpec.describe Application do
  it 'generates unique token' do
    app = Application.create(name: 'Test')
    expect(app.token).to be_present
  end
end
```

**Request Spec:**
```
# spec/requests/applications_spec.rb
RSpec.describe 'Applications API' do
  it 'creates application without exposing ID' do
    post '/api/v1/applications', params: {name: 'Test'}
    json = JSON.parse(response.body)
    expect(json).to have_key('token')
    expect(json).not_to have_key('id')
  end
end

---

## Troubleshooting

### Services Won't Start

```
# Check logs
docker-compose logs

# Rebuild from scratch
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

### MySQL Connection Issues

```
# Wait for MySQL initialization (2-3 minutes first time)
docker-compose logs mysql | grep "ready for connections"

# Restart dependent services
docker-compose restart rails-api golang-service
```

### Search Not Working

```
# Create index
docker exec -it chat-system-rails bundle exec rails runner \
  'Message.__elasticsearch__.create_index! force: true'

# Reindex messages
docker exec -it chat-system-rails bundle exec rails runner \
  'Message.import force: true'

# Wait 5-10 seconds
sleep 10
```

### Port Already in Use

```
# Find process using port
lsof -i :3000  # Mac/Linux
netstat -ano | findstr :3000  # Windows

# Change port in docker-compose.yml
ports:
  - "3001:3000"
```

### Check Docker Resources

Ensure Docker has sufficient resources:
- Memory: Minimum 4GB
- CPU: 2+ cores recommended
- Disk: 20GB free space

## Performance Optimization

### Database Indices

All tables have optimized indices:
- Applications: token index for fast lookups
- Chats: Composite index on (application_id, number)
- Messages: Composite index on (chat_id, number)
- Unique constraints prevent duplicates

### Caching Strategy

- Redis caches frequently accessed data
- Sequential numbering via Redis (no DB queries)
- Background jobs for non-critical operations

### Query Optimization

- Eager loading to prevent N+1 queries
- Database connection pooling
- Prepared statements for security and performance

## Development Commands

### Rails Console

```
docker exec -it chat-system-rails bundle exec rails console
```

### Run Migrations

```
docker exec -it chat-system-rails bundle exec rails db:migrate
```

### View Sidekiq Jobs

```
docker-compose logs -f sidekiq
```

### Access Redis CLI

```
docker exec -it chat-system-redis redis-cli
```

### Stop Services

```
docker-compose down
```

### Remove All Data

```
docker-compose down -v
```

## Architecture Decisions

### Why Microservices?

- **Rails**: Better for complex business logic and read operations
- **Golang**: 10x faster for write-heavy operations
- **Scalability**: Services scale independently

### Why Redis?

- Distributed locking for race conditions
- Fast sequential number generation
- Job queue for Sidekiq
- Caching layer

### Why Elasticsearch?

- Faster than MySQL FULLTEXT search
- Better relevance ranking
- Scales horizontally
- Real-time indexing

### Why Sidekiq?

- Background processing for counters
- Asynchronous Elasticsearch indexing
- Non-blocking operations

## Project Structure

```
chat-system-app/
├── chat-system-api/          # Rails API
│   ├── app/
│   │   ├── controllers/      # API endpoints
│   │   ├── models/           # ActiveRecord models
│   │   ├── jobs/             # Sidekiq jobs
│   │   └── swagger/          # API documentation
│   ├── config/               # Rails configuration
│   ├── db/
│   │   └── migrate/          # Database migrations
│   ├── Dockerfile
│   └── Gemfile
├── golang-service/           # Golang service
│   ├── main.go               # Entry point
│   ├── handlers/             # HTTP handlers
│   ├── models/               # Data models
│   ├── Dockerfile
│   └── go.mod
├── docker-compose.yml        # Service orchestration
├── .gitignore
└── README.md






