package models

import "time"

// Request models
type ChatCreateRequest struct {
	ApplicationToken string `json:"application_token" validate:"required,min=20,max=20"`
}

type MessageCreateRequest struct {
	ApplicationToken string `json:"application_token" validate:"required,min=20,max=20"`
	ChatNumber       int    `json:"chat_number" validate:"required,min=1"`
	Body             string `json:"body" validate:"required,min=1,max=5000"`
}

// Response models
type ChatResponse struct {
	Number        int       `json:"number"`
	MessagesCount int       `json:"messages_count"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

type MessageResponse struct {
	Number    int       `json:"number"`
	Body      string    `json:"body"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type HealthResponse struct {
	Status  string            `json:"status"`
	Service string            `json:"service"`
	Version string            `json:"version"`
	Checks  map[string]string `json:"checks,omitempty"`
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message,omitempty"`
	Status  int    `json:"status"`
}

// Database models
type Application struct {
	ID         int64
	Token      string
	Name       string
	ChatsCount int
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type Chat struct {
	ID             int64
	ApplicationID  int64
	Number         int
	MessagesCount  int
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

type Message struct {
	ID        int64
	ChatID    int64
	Number    int
	Body      string
	CreatedAt time.Time
	UpdatedAt time.Time
}
