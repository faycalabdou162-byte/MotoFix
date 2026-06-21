package middleware

import (
	"net/http"

	"github.com/urbanmobilityai/platform/libs/go/platform/httpx"
)

func Idempotency(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost || r.Method == http.MethodPatch {
			if r.URL.Path == "/v1/auth/session/exchange" {
				next.ServeHTTP(w, r)
				return
			}
			if r.Header.Get("Idempotency-Key") == "" {
				httpx.Error(w, http.StatusBadRequest, "missing_idempotency_key", "Idempotency-Key header is required")
				return
			}
		}
		next.ServeHTTP(w, r)
	})
}
