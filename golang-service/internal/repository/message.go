package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/AhmedAbdelbasetAli/chat-service/internal/models"
)

type MessageRepository struct {
	db *sql.DB
}

func NewMessageRepository(db *sql.DB) *MessageRepository {
	return &MessageRepository{db: db}
}

// Create inserts a new message
func (r *MessageRepository) Create(chatID int64, number int, body string) (*models.Message, error) {
	now := time.Now()
	
	query := `INSERT INTO messages (chat_id, number, body, created_at, updated_at) 
	          VALUES (?, ?, ?, ?, ?)`
	
	result, err := r.db.Exec(query, chatID, number, body, now, now)
	if err != nil {
		return nil, fmt.Errorf("failed to create message: %w", err)
	}
	
	messageID, err := result.LastInsertId()
	if err != nil {
		return nil, fmt.Errorf("failed to get message ID: %w", err)
	}
	
	message := &models.Message{
		ID:        messageID,
		ChatID:    chatID,
		Number:    number,
		Body:      body,
		CreatedAt: now,
		UpdatedAt: now,
	}
	
	return message, nil
}
