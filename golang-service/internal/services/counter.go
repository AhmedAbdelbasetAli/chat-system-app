package services

import (
	"context"
	"fmt"

	"github.com/redis/go-redis/v9"
)

type CounterService struct {
	redis *redis.Client
	ctx   context.Context
}

func NewCounterService(redisClient *redis.Client) *CounterService {
	return &CounterService{
		redis: redisClient,
		ctx:   context.Background(),
	}
}

// GetNextChatNumber atomically increments and returns next chat number
func (s *CounterService) GetNextChatNumber(appToken string) (int64, error) {
	key := fmt.Sprintf("app:%s:chat_counter", appToken)
	
	number, err := s.redis.Incr(s.ctx, key).Result()
	if err != nil {
		return 0, fmt.Errorf("failed to increment chat counter: %w", err)
	}
	
	return number, nil
}

// GetNextMessageNumber atomically increments and returns next message number
func (s *CounterService) GetNextMessageNumber(chatID int64) (int64, error) {
	key := fmt.Sprintf("chat:%d:message_counter", chatID)
	
	number, err := s.redis.Incr(s.ctx, key).Result()
	if err != nil {
		return 0, fmt.Errorf("failed to increment message counter: %w", err)
	}
	
	return number, nil
}

// InitializeMessageCounter sets initial value for chat's message counter
func (s *CounterService) InitializeMessageCounter(chatID int64) error {
	key := fmt.Sprintf("chat:%d:message_counter", chatID)
	
	err := s.redis.SetNX(s.ctx, key, 0, 0).Err()
	if err != nil {
		return fmt.Errorf("failed to initialize message counter: %w", err)
	}
	
	return nil
}
