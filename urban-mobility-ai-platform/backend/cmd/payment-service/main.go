package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/domain"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/events"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/config"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/health"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httpserver"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httputil"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/kafka"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/middleware"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/encoding"
)

type authorizeRequest struct {
	CityID     string      `json:"cityId"`
	TripID     string      `json:"tripId"`
	Method     string      `json:"method"`
	Amount     domain.Money `json:"amount"`
	ProviderRef string     `json:"providerRef"`
}

func main() {
	cfg := config.Load("payment-service")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	producer := kafka.NewProducer(cfg.KafkaBrokers, "mobility-events")
	defer func() { _ = producer.Close() }()

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)
	r.Mount("/", health.Router())

	r.Route("/v1/payments", func(r chi.Router) {
		r.Use(middleware.InternalAuth(cfg.InternalJWTSecret))

		r.Post("/authorize", func(w http.ResponseWriter, r *http.Request) {
			var req authorizeRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			if req.CityID == "" || req.TripID == "" || req.Amount.Currency == "" || req.Amount.Amount <= 0 {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			claims, ok := middleware.InternalClaimsFromContext(r.Context())
			if !ok {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			if req.CityID != claims.CityID {
				w.WriteHeader(http.StatusBadRequest)
				return
			}

			env := events.EventEnvelope[authorizeRequest]{
				EventID:     newID(),
				EventType:   events.EventPaymentAuthorized,
				OccurredAt:  time.Now().UTC(),
				CityID:      req.CityID,
				AggregateID: req.TripID,
				Data:        req,
			}
			_ = producer.Write(r.Context(), req.TripID, encoding.MustJSON(env))

			httputil.WriteJSON(w, http.StatusOK, map[string]any{"status": "authorized"})
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

func newID() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	return hex.EncodeToString(b[:])
}
