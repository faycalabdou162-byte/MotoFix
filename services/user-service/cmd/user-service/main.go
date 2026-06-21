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
	cfg := config.Load("user-service", 8082)
	logger := logx.New(cfg.Name)
	r := chi.NewRouter()
	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		httpx.JSON(w, http.StatusOK, map[string]any{"service": cfg.Name, "status": "ok"})
	})
	r.Get("/v1/users/me", func(w http.ResponseWriter, _ *http.Request) {
		httpx.JSON(w, http.StatusOK, map[string]any{"profile_owner": "user-service"})
	})
	server := platformruntime.NewHTTPServer(cfg, r)
	logger.Info("starting service", "port", cfg.Port)
	_ = server.ListenAndServe()
}
