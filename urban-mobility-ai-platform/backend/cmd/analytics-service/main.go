package main

import (
	"context"
	"encoding/json"
	"net/http"
	"os/signal"
	"syscall"

	"github.com/go-chi/chi/v5"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/config"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/health"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httpserver"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httputil"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/kafka"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/middleware"
)

func main() {
	cfg := config.Load("analytics-service")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	consumer := kafka.NewConsumer(cfg.KafkaBrokers, "analytics-service", "mobility-events")
	defer func() { _ = consumer.Close() }()

	go loop(ctx, consumer)

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)
	r.Mount("/", health.Router())
	r.Get("/v1/analytics/ping", func(w http.ResponseWriter, r *http.Request) {
		httputil.WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
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

func loop(ctx context.Context, consumer *kafka.Consumer) {
	for {
		select {
		case <-ctx.Done():
			return
		default:
		}
		m, err := consumer.Fetch(ctx)
		if err != nil {
			continue
		}
		var env struct {
			EventType string          `json:"eventType"`
			CityID    string          `json:"cityId"`
			Data      json.RawMessage `json:"data"`
		}
		_ = json.Unmarshal(m.Value, &env)
		_ = consumer.Commit(ctx, m)
	}
}
