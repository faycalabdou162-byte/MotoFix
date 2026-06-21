package main

import (
	"context"
	"encoding/json"
	"encoding/base64"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	jwt "github.com/golang-jwt/jwt/v5"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/config"
	fb "github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/firebase"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/health"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httpserver"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httputil"
	internaljwt "github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/jwt"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/middleware"
)

type tokenExchangeRequest struct {
	CityID    string `json:"cityId"`
	ActorType string `json:"actorType"`
	Role      string `json:"role"`
}

type tokenExchangeResponse struct {
	InternalToken string `json:"internalToken"`
	ExpiresInSec  int64  `json:"expiresInSec"`
}

func main() {
	cfg := config.Load("auth-service")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	var creds []byte
	if b64 := os.Getenv("FIREBASE_ADMIN_CREDENTIALS_B64"); b64 != "" {
		decoded, err := base64.StdEncoding.DecodeString(b64)
		if err == nil {
			creds = decoded
		}
	}
	verifier, err := fb.NewAuthVerifier(ctx, cfg.FirebaseProjectID, creds)
	if err != nil {
		panic(err)
	}

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)

	r.Mount("/", health.Router())

	r.Route("/v1/auth", func(r chi.Router) {
		r.With(middleware.FirebaseAuth(verifier)).Post("/exchange", func(w http.ResponseWriter, r *http.Request) {
			var req tokenExchangeRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			tok, ok := middleware.FirebaseTokenFromContext(r.Context())
			if !ok {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}

			exp := time.Now().Add(15 * time.Minute)
			internal, err := internaljwt.SignInternal(cfg.InternalJWTSecret, internaljwt.InternalClaims{
				Subject:   tok.UID,
				Role:      req.Role,
				CityID:    req.CityID,
				ActorType: req.ActorType,
				RegisteredClaims: jwt.RegisteredClaims{ExpiresAt: jwt.NewNumericDate(exp)},
			})
			if err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			httputil.WriteJSON(w, http.StatusOK, tokenExchangeResponse{InternalToken: internal, ExpiresInSec: int64(time.Until(exp).Seconds())})
		})
	})

	srv := httpserver.New(cfg.HTTPAddr, r)
	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
		defer cancel()
		_ = srv.Shutdown(shutdownCtx)
	}()

	if err := srv.ListenAndServe(ctx); err != nil && err != context.Canceled {
		panic(err)
	}
}

func decodeJSON(r *http.Request, v any) error {
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	return dec.Decode(v)
}
