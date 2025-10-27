package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	

	"github.com/AhmedAbdelbasetAli/chat-service/internal/models"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/repository"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/services"
)

type MessageHandler struct {
	appRepo     *repository.ApplicationRepository
	chatRepo    *repository.ChatRepository
	messageRepo *repository.MessageRepository
	counterSvc  *services.CounterService
}

func NewMessageHandler(
	appRepo *repository.ApplicationRepository,
	chatRepo *repository.ChatRepository,
	messageRepo *repository.MessageRepository,
	counterSvc *services.CounterService,
) *MessageHandler {
	return &MessageHandler{
		appRepo:     appRepo,
		chatRepo:    chatRepo,
		messageRepo: messageRepo,
		counterSvc:  counterSvc,
	}
}

func (h *MessageHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Parse request
	var req models.MessageCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}
	
	// Validate inputs
	if err := services.ValidateToken(req.ApplicationToken); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid token", err.Error())
		return
	}
	
	if err := services.ValidateChatNumber(req.ChatNumber); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid chat number", err.Error())
		return
	}
	
	if err := services.ValidateMessageBody(req.Body); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid message body", err.Error())
		return
	}
	
	// Get application
	app, err := h.appRepo.GetByToken(req.ApplicationToken)
	if err != nil {
		respondError(w, http.StatusNotFound, "Application not found", err.Error())
		return
	}
	
	// Get chat
	chat, err := h.chatRepo.GetByApplicationAndNumber(app.ID, req.ChatNumber)
	if err != nil {
		respondError(w, http.StatusNotFound, "Chat not found", err.Error())
		return
	}
	
	// Get next message number (atomic)
	messageNumber, err := h.counterSvc.GetNextMessageNumber(chat.ID)
	if err != nil {
		log.Printf("Error getting message number: %v", err)
		respondError(w, http.StatusInternalServerError, "Failed to generate message number", err.Error())
		return
	}
	
	// Create message in database
	message, err := h.messageRepo.Create(chat.ID, int(messageNumber), req.Body)
	if err != nil {
		log.Printf("Error creating message: %v", err)
		respondError(w, http.StatusInternalServerError, "Failed to create message", err.Error())
		return
	}
	
	// Respond
	response := models.MessageResponse{
		Number:    message.Number,
		Body:      message.Body,
		CreatedAt: message.CreatedAt,
		UpdatedAt: message.UpdatedAt,
	}
	
	log.Printf("✅ Created message #%d for chat %d", messageNumber, chat.ID)
	respondJSON(w, http.StatusCreated, response)
}
