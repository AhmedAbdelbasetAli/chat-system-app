package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/AhmedAbdelbasetAli/chat-service/internal/models"
)

type ChatRepository struct {
	db *sql.DB
}

func NewChatRepository(db *sql.DB) *ChatRepository {
	return &ChatRepository{db: db}
}

// Create inserts a new chat
func (r *ChatRepository) Create(appID int64, number int) (*models.Chat, error) {
	now := time.Now()
	
	query := `INSERT INTO chats (application_id, number, messages_count, created_at, updated_at) 
	          VALUES (?, ?, ?, ?, ?)`
	
	result, err := r.db.Exec(query, appID, number, 0, now, now)
	if err != nil {
		return nil, fmt.Errorf("failed to create chat: %w", err)
	}
	
	chatID, err := result.LastInsertId()
	if err != nil {
		return nil, fmt.Errorf("failed to get chat ID: %w", err)
	}
	
	chat := &models.Chat{
		ID:             chatID,
		ApplicationID:  appID,
		Number:         number,
		MessagesCount:  0,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
	
	return chat, nil
}

// GetByApplicationAndNumber retrieves chat by app ID and chat number
func (r *ChatRepository) GetByApplicationAndNumber(appID int64, number int) (*models.Chat, error) {
	var chat models.Chat
	
	query := `SELECT id, application_id, number, messages_count, created_at, updated_at 
	          FROM chats 
	          WHERE application_id = ? AND number = ? LIMIT 1`
	
	err := r.db.QueryRow(query, appID, number).Scan(
		&chat.ID,
		&chat.ApplicationID,
		&chat.Number,
		&chat.MessagesCount,
		&chat.CreatedAt,
		&chat.UpdatedAt,
	)
	
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("chat not found")
	}
	
	if err != nil {
		return nil, fmt.Errorf("database error: %w", err)
	}
	
	return &chat, nil
}
