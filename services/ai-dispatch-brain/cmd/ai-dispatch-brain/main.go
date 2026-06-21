package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/urbanmobilityai/platform/libs/go/platform/config"
	"github.com/urbanmobilityai/platform/libs/go/platform/httpx"
	"github.com/urbanmobilityai/platform/libs/go/platform/logx"
	platformruntime "github.com/urbanmobilityai/platform/libs/go/platform/runtime"
	"github.com/urbanmobilityai/platform/services/ai-dispatch-brain/internal/acceptance"
	"github.com/urbanmobilityai/platform/services/ai-dispatch-brain/internal/demand"
	"github.com/urbanmobilityai/platform/services/ai-dispatch-brain/internal/eta"
	"github.com/urbanmobilityai/platform/services/ai-dispatch-brain/internal/fallback"
	"github.com/urbanmobilityai/platform/services/ai-dispatch-brain/internal/scoring"
	"github.com/urbanmobilityai/platform/services/ai-dispatch-brain/internal/surge"
	"github.com/urbanmobilityai/platform/services/ai-dispatch-brain/internal/swarm"
)

func main() {
	cfg := config.Load("ai-dispatch-brain", 8086)
	logger := logx.New(cfg.Name)
	r := chi.NewRouter()
	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		httpx.JSON(w, http.StatusOK, map[string]any{"service": cfg.Name, "status": "ok"})
	})
	r.Get("/v1/ai/dispatch/demo", func(w http.ResponseWriter, _ *http.Request) {
		acceptanceProb := acceptance.Probability(4.8, 0.94, 0.89)
		dispatchScore := scoring.DispatchScore(scoring.RequestFeatures{
			DistanceWeight:        2.8,
			DriverRating:          4.8,
			Availability:          1.0,
			TrafficPrediction:     0.8,
			VehicleMatch:          1.0,
			AcceptanceProbability: acceptanceProb,
			FraudPenalty:          0.1,
			StaleGPSPenalty:       0.0,
		})
		httpx.JSON(w, http.StatusOK, map[string]any{
			"acceptance_probability": acceptanceProb,
			"dispatch_score":         dispatchScore,
			"eta_seconds":            eta.Predict(1800, 1.2),
			"demand_forecast":        demand.Forecast(150, 1.1, 1.3),
			"surge_multiplier":       surge.PriceMultiplier(1.4, 1.1, 1.2),
			"swarm_recommendation":   swarm.Reposition("niamey-centre", 12, 0.87),
			"execution_mode":         fallback.BandwidthSafeMode(true, 48),
		})
	})
	server := platformruntime.NewHTTPServer(cfg, r)
	logger.Info("starting service", "port", cfg.Port)
	_ = server.ListenAndServe()
}
