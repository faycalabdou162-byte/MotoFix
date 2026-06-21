package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/go-chi/chi/v5"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/config"
	fb "github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/firebase"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/health"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httpserver"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httputil"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/middleware"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/postgres"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/user"
)

type upsertMeRequest struct {
	CityID string `json:"cityId"`
	Phone  string `json:"phone"`
	Name   string `json:"name"`
}

func main() {
	cfg := config.Load("user-service")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	db, err := postgres.Connect(ctx, cfg.PostgresURL)
	if err != nil {
		panic(err)
	}
	defer db.Close()

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

	repo := user.NewRepository(db)

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)
	r.Mount("/", health.Router())

	r.Route("/v1/users", func(r chi.Router) {
		r.Use(middleware.FirebaseAuth(verifier))

		r.Get("/me", func(w http.ResponseWriter, r *http.Request) {
			tok, ok := middleware.FirebaseTokenFromContext(r.Context())
			if !ok {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			cityID := r.URL.Query().Get("cityId")
			if cityID == "" {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			u, err := repo.Get(r.Context(), cityID, tok.UID)
			if err != nil {
				w.WriteHeader(http.StatusNotFound)
				return
			}
			httputil.WriteJSON(w, http.StatusOK, u)
		})

		r.Post("/me", func(w http.ResponseWriter, r *http.Request) {
			var req upsertMeRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			if req.CityID == "" {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			tok, ok := middleware.FirebaseTokenFromContext(r.Context())
			if !ok {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			u, err := repo.Upsert(r.Context(), user.User{
				ID:     tok.UID,
				CityID: req.CityID,
				Phone:  req.Phone,
				Name:   req.Name,
			})
			if err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			httputil.WriteJSON(w, http.StatusOK, u)
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
