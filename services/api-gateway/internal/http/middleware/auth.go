package middleware

import (
	"net/http"
	"strings"

	"github.com/urbanmobilityai/platform/libs/go/platform/httpx"
)

func Auth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/healthz" || r.URL.Path == "/readyz" || r.URL.Path == "/v1/auth/session/exchange" {
			next.ServeHTTP(w, r)
			return
		}

		authHeader := r.Header.Get("Authorization")
		if !strings.HasPrefix(authHeader, "Bearer ") {
			httpx.Error(w, http.StatusUnauthorized, "missing_bearer_token", "Authorization header is required")
			return
		}

		next.ServeHTTP(w, r)
	})
}
