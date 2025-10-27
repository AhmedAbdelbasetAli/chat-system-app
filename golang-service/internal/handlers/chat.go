package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	
	"github.com/AhmedAbdelbasetAli/chat-service/internal/models"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/repository"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/services"
)

type ChatHandler struct {
	appRepo      *repository.ApplicationRepository
	chatRepo     *repository.ChatRepository
	counterSvc   *services.CounterService
}

func NewChatHandler(
	appRepo *repository.ApplicationRepository,
	chatRepo *repository.ChatRepository,
	counterSvc *services.CounterService,
) *ChatHandler {
	return &ChatHandler{
		appRepo:    appRepo,
		chatRepo:   chatRepo,
		counterSvc: counterSvc,
	}
}

func (h *ChatHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Parse request
	var req models.ChatCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}
	
	// Validate token
	if err := services.ValidateToken(req.ApplicationToken); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid token", err.Error())
		return
	}
	
	// Get application
	app, err := h.appRepo.GetByToken(req.ApplicationToken)
	if err != nil {
		respondError(w, http.StatusNotFound, "Application not found", err.Error())
		return
	}
	
	// Get next chat number (atomic)
	chatNumber, err := h.counterSvc.GetNextChatNumber(app.Token)
	if err != nil {
		log.Printf("Error getting chat number: %v", err)
		respondError(w, http.StatusInternalServerError, "Failed to generate chat number", err.Error())
		return
	}
	
	// Create chat in database
	chat, err := h.chatRepo.Create(app.ID, int(chatNumber))
	if err != nil {
		log.Printf("Error creating chat: %v", err)
		respondError(w, http.StatusInternalServerError, "Failed to create chat", err.Error())
		return
	}
	
	// Initialize message counter for this chat
	if err := h.counterSvc.InitializeMessageCounter(chat.ID); err != nil {
		log.Printf("Warning: Failed to initialize message counter: %v", err)
	}
	
	// Respond
	response := models.ChatResponse{
		Number:        chat.Number,
		MessagesCount: chat.MessagesCount,
		CreatedAt:     chat.CreatedAt,
		UpdatedAt:     chat.UpdatedAt,
	}
	
	log.Printf("✅ Created chat #%d for app %s", chatNumber, app.Token)
	respondJSON(w, http.StatusCreated, response)
}
