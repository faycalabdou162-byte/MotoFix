package middleware

import (
	"net/http"

	"github.com/go-chi/httprate"
)

func RateLimit(requestsPerMinute int) func(http.Handler) http.Handler {
	return httprate.Limit(
		requestsPerMinute,
		1,
		httprate.WithKeyFuncs(func(r *http.Request) (string, error) {
			if user := r.Header.Get("X-User-ID"); user != "" {
				return user, nil
			}
			return r.RemoteAddr, nil
		}),
	)
}
