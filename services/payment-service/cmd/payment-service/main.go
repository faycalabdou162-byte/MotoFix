package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/urbanmobilityai/platform/libs/go/platform/config"
	"github.com/urbanmobilityai/platform/libs/go/platform/httpx"
	"github.com/urbanmobilityai/platform/libs/go/platform/logx"
	platformruntime "github.com/urbanmobilityai/platform/libs/go/platform/runtime"
)

func main() {
	cfg := config.Load("payment-service", 8088)
	logger := logx.New(cfg.Name)
	r := chi.NewRouter()
	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		httpx.JSON(w, http.StatusOK, map[string]any{"service": cfg.Name, "status": "ok"})
	})
	r.Post("/v1/payments/intents", func(w http.ResponseWriter, _ *http.Request) {
		httpx.JSON(w, http.StatusAccepted, map[string]any{"validation": "server_side_only"})
	})
	server := platformruntime.NewHTTPServer(cfg, r)
	logger.Info("starting service", "port", cfg.Port)
	_ = server.ListenAndServe()
}
