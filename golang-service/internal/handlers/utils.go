package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/AhmedAbdelbasetAli/chat-service/internal/models"
)

func respondJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

func respondError(w http.ResponseWriter, statusCode int, message, details string) {
	response := models.ErrorResponse{
		Error:   message,
		Message: details,
		Status:  statusCode,
	}
	respondJSON(w, statusCode, response)
}
