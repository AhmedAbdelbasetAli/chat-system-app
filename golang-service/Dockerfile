# Build stage
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o chat-service ./cmd/server/main.go

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /home/appuser

# Copy binary from builder
COPY --from=builder /app/chat-service .

# Copy .env if it exists (optional, won't fail if missing)
COPY --from=builder /app/.env .env* ./

# Change ownership
RUN chown -R appuser:appgroup /home/appuser

# Switch to non-root user  
USER appuser

EXPOSE 8080

CMD ["./chat-service"]
