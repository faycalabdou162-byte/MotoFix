package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/urbanmobilityai/platform/libs/go/platform/config"
	"github.com/urbanmobilityai/platform/libs/go/platform/httpx"
	"github.com/urbanmobilityai/platform/libs/go/platform/logx"
	platformruntime "github.com/urbanmobilityai/platform/libs/go/platform/runtime"
	"github.com/urbanmobilityai/platform/services/dispatch-service/internal/matching"
)

func main() {
	cfg := config.Load("dispatch-service", 8085)
	logger := logx.New(cfg.Name)
	r := chi.NewRouter()
	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		httpx.JSON(w, http.StatusOK, map[string]any{"service": cfg.Name, "status": "ok", "sla_ms": 100})
	})
	r.Get("/v1/dispatch/rank-demo", func(w http.ResponseWriter, _ *http.Request) {
		candidates := matching.Rank([]matching.Candidate{
			{DriverID: "driver-a", DistanceMeters: 420, Rating: 4.9, Availability: 1, VehicleMatch: 1, AcceptanceProb: 0.91, TrafficPenalty: 0.15},
			{DriverID: "driver-b", DistanceMeters: 300, Rating: 4.6, Availability: 1, VehicleMatch: 1, AcceptanceProb: 0.70, TrafficPenalty: 0.35},
			{DriverID: "driver-c", DistanceMeters: 560, Rating: 4.95, Availability: 1, VehicleMatch: 1, AcceptanceProb: 0.88, TrafficPenalty: 0.10},
		})
		httpx.JSON(w, http.StatusOK, map[string]any{
			"ranked_candidates": candidates,
			"fallback_chain":    matching.DefaultFallbackChain(),
			"sla":               matching.DefaultSLA(),
		})
	})
	server := platformruntime.NewHTTPServer(cfg, r)
	logger.Info("starting service", "port", cfg.Port)
	_ = server.ListenAndServe()
}
