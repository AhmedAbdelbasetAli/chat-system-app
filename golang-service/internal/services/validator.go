package services

import (
	"fmt"
	"regexp"
)

var tokenRegex = regexp.MustCompile(`^[a-f0-9]{20}$`)

// ValidateToken validates application token format
func ValidateToken(token string) error {
	if token == "" {
		return fmt.Errorf("token is required")
	}
	if len(token) != 20 {
		return fmt.Errorf("token must be exactly 20 characters")
	}
	if !tokenRegex.MatchString(token) {
		return fmt.Errorf("token must be hexadecimal")
	}
	return nil
}

// ValidateMessageBody validates message body
func ValidateMessageBody(body string) error {
	if body == "" {
		return fmt.Errorf("message body is required")
	}
	if len(body) > 5000 {
		return fmt.Errorf("message body must be less than 5000 characters")
	}
	return nil
}

// ValidateChatNumber validates chat number
func ValidateChatNumber(number int) error {
	if number < 1 {
		return fmt.Errorf("chat number must be positive")
	}
	return nil
}
