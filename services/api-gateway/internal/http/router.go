package http

import (
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/urbanmobilityai/platform/services/api-gateway/internal/config"
	"github.com/urbanmobilityai/platform/services/api-gateway/internal/http/handlers"
	custommiddleware "github.com/urbanmobilityai/platform/services/api-gateway/internal/http/middleware"
)

func NewRouter(logger *slog.Logger, cfg config.Gateway) http.Handler {
	r := chi.NewRouter()
	r.Use(chimiddleware.Recoverer)
	r.Use(chimiddleware.RealIP)
	r.Use(custommiddleware.RequestContext)
	r.Use(custommiddleware.RateLimit(cfg.RateLimitRPM))
	r.Use(custommiddleware.Auth)
	r.Use(custommiddleware.Idempotency)

	r.Get("/healthz", handlers.Health)
	r.Get("/readyz", handlers.Ready)

	r.Route("/v1", func(r chi.Router) {
		r.Route("/auth", func(r chi.Router) {
			r.Post("/session/exchange", handlers.SessionExchange)
		})
		r.Get("/me", handlers.Me)
		r.Post("/trips/quote", handlers.TripQuote)
		r.Post("/trips", handlers.TripCreate)
	})

	logger.Info("gateway routes initialized")
	return r
}
