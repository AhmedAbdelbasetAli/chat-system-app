package repository

import (
	"database/sql"
	"fmt"

	"github.com/AhmedAbdelbasetAli/chat-service/internal/models"
)

type ApplicationRepository struct {
	db *sql.DB
}

func NewApplicationRepository(db *sql.DB) *ApplicationRepository {
	return &ApplicationRepository{db: db}
}

// GetByToken retrieves application by token
func (r *ApplicationRepository) GetByToken(token string) (*models.Application, error) {
	var app models.Application
	
	query := `SELECT id, token, name, chats_count, created_at, updated_at 
	          FROM applications 
	          WHERE token = ? LIMIT 1`
	
	err := r.db.QueryRow(query, token).Scan(
		&app.ID,
		&app.Token,
		&app.Name,
		&app.ChatsCount,
		&app.CreatedAt,
		&app.UpdatedAt,
	)
	
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("application not found")
	}
	
	if err != nil {
		return nil, fmt.Errorf("database error: %w", err)
	}
	
	return &app, nil
}
