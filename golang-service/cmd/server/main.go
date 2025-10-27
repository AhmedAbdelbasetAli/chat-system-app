package main

import (
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/AhmedAbdelbasetAli/chat-service/internal/config"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/database"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/handlers"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/middleware"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/repository"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/services"
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	
)

func main() {
	// Load .env file (ignore error if file doesn't exist)
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}
	
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("Failed to load config:", err)
	}
	
	// Initialize databases
	if err := database.InitMySQL(cfg); err != nil {
		log.Fatal("Failed to initialize MySQL:", err)
	}
	defer database.CloseMySQL()
	
	if err := database.InitRedis(cfg); err != nil {
		log.Fatal("Failed to initialize Redis:", err)
	}
	defer database.CloseRedis()
	
	// Initialize repositories
	appRepo := repository.NewApplicationRepository(database.DB)
	chatRepo := repository.NewChatRepository(database.DB)
	messageRepo := repository.NewMessageRepository(database.DB)
	
	// Initialize services
	counterSvc := services.NewCounterService(database.RedisClient)
	
	// Initialize handlers
	healthHandler := handlers.NewHealthHandler()
	chatHandler := handlers.NewChatHandler(appRepo, chatRepo, counterSvc)
	messageHandler := handlers.NewMessageHandler(appRepo, chatRepo, messageRepo, counterSvc)
	
	// Setup router
	router := mux.NewRouter()
	
	// Apply security middleware (order matters!)
	router.Use(middleware.SecurityHeadersMiddleware)
	router.Use(middleware.CORSMiddleware)
	router.Use(middleware.RateLimitMiddleware)
	router.Use(middleware.AuthMiddleware)
	router.Use(middleware.RequestSizeMiddleware)
	
	// Register handlers
	router.Handle("/health", healthHandler).Methods("GET", "OPTIONS")
	router.Handle("/api/v1/chats", chatHandler).Methods("POST", "OPTIONS")
	router.Handle("/api/v1/messages", messageHandler).Methods("POST", "OPTIONS")
	
	// Setup graceful shutdown
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	
	
	// Start server
	addr := ":" + cfg.Server.Port
	log.Printf("🚀 Golang service starting on port %s", cfg.Server.Port)
	log.Printf("🔒 Security features: Rate limiting, CORS, Request size limits")
	
	// Check if API key is required
	if os.Getenv("SKIP_API_KEY_CHECK") == "true" {
		log.Println("⚠️  API key check disabled (development mode)")
	} else {
		log.Println("🔐 API key authentication enabled")
	}
	
	go func() {
		if err := http.ListenAndServe(addr, router); err != nil {
			log.Fatal("Server error:", err)
		}
	}()
	
	// Wait for interrupt signal
	<-stop
	log.Println("Shutting down gracefully...")
}
