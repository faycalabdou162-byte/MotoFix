package middleware

import (
	"context"
	"net/http"
	"strings"

	internaljwt "github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/jwt"
)

type internalAuthCtxKey int

const internalAuthKey internalAuthCtxKey = 1

func InternalAuth(secret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			h := r.Header.Get("Authorization")
			if h == "" || !strings.HasPrefix(h, "Bearer ") {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			token := strings.TrimSpace(strings.TrimPrefix(h, "Bearer "))
			claims, err := internaljwt.VerifyInternal(secret, token)
			if err != nil {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			ctx := context.WithValue(r.Context(), internalAuthKey, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func InternalClaimsFromContext(ctx context.Context) (internaljwt.InternalClaims, bool) {
	v := ctx.Value(internalAuthKey)
	claims, ok := v.(internaljwt.InternalClaims)
	return claims, ok
}

