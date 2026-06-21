package httpx

import (
	"encoding/json"
	"net/http"
)

func JSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func Error(w http.ResponseWriter, status int, code, message string) {
	JSON(w, status, map[string]any{
		"error": map[string]any{
			"code":    code,
			"message": message,
		},
	})
}
