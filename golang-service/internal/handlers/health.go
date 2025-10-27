package handlers

import (
	"net/http"
	

	"github.com/AhmedAbdelbasetAli/chat-service/internal/database"
	"github.com/AhmedAbdelbasetAli/chat-service/internal/models"
)

type HealthHandler struct{}

func NewHealthHandler() *HealthHandler {
	return &HealthHandler{}
}

func (h *HealthHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	checks := make(map[string]string)
	status := "healthy"
	
	// Check MySQL
	if err := database.DB.Ping(); err != nil {
		checks["mysql"] = "unhealthy"
		status = "unhealthy"
	} else {
		checks["mysql"] = "ok"
	}
	
	// Check Redis
	if err := database.RedisClient.Ping(database.Ctx).Err(); err != nil {
		checks["redis"] = "unhealthy"
		status = "unhealthy"
	} else {
		checks["redis"] = "ok"
	}
	
	response := models.HealthResponse{
		Status:  status,
		Service: "golang-chat-service",
		Version: "1.0.0",
		Checks:  checks,
	}
	
	statusCode := http.StatusOK
	if status == "unhealthy" {
		statusCode = http.StatusServiceUnavailable
	}
	
	respondJSON(w, statusCode, response)
}
