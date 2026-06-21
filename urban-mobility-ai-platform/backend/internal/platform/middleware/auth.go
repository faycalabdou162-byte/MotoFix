package middleware

import (
	"context"
	"net/http"
	"strings"

	fbauth "firebase.google.com/go/v4/auth"
)

type ctxKey int

const authKey ctxKey = 2

type FirebaseAuthVerifier interface {
	VerifyIDToken(ctx context.Context, idToken string) (*fbauth.Token, error)
}

func FirebaseAuth(verifier FirebaseAuthVerifier) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			h := r.Header.Get("Authorization")
			if h == "" || !strings.HasPrefix(h, "Bearer ") {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			idToken := strings.TrimSpace(strings.TrimPrefix(h, "Bearer "))
			tok, err := verifier.VerifyIDToken(r.Context(), idToken)
			if err != nil {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			ctx := context.WithValue(r.Context(), authKey, tok)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func FirebaseTokenFromContext(ctx context.Context) (*fbauth.Token, bool) {
	v := ctx.Value(authKey)
	t, ok := v.(*fbauth.Token)
	return t, ok
}

