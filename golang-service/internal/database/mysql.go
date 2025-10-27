package database

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	"github.com/AhmedAbdelbasetAli/chat-service/internal/config"
	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

// InitMySQL initializes MySQL connection
func InitMySQL(cfg *config.Config) error {
	var err error
	
	DB, err = sql.Open("mysql", cfg.DSN())
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}

	// Configure connection pool
	DB.SetMaxOpenConns(cfg.Database.MaxConns)
	DB.SetMaxIdleConns(cfg.Database.MaxConns / 2)
	DB.SetConnMaxLifetime(5 * time.Minute)
	DB.SetConnMaxIdleTime(1 * time.Minute)

	// Test connection
	if err = DB.Ping(); err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}

	log.Println("✅ Connected to MySQL")
	return nil
}

// CloseMySQL closes MySQL connection
func CloseMySQL() error {
	if DB != nil {
		return DB.Close()
	}
	return nil
}
