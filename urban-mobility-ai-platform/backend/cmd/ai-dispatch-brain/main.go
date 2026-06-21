package main

import (
	"context"
	"encoding/json"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/dispatchbrain"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/config"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/health"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httpserver"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httputil"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/middleware"
)

type rankRequest struct {
	Weights    dispatchbrain.ScoringWeights `json:"weights"`
	Candidates []dispatchbrain.Candidate    `json:"candidates"`
}

type demandObserveRequest struct {
	CityID string  `json:"cityId"`
	ZoneID string  `json:"zoneId"`
	Count  float64 `json:"count"`
}

type demandPredictRequest struct {
	CityID string `json:"cityId"`
	ZoneID string `json:"zoneId"`
}

func main() {
	cfg := config.Load("ai-dispatch-brain")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	predictor := dispatchbrain.NewDemandPredictor(0.2)

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)
	r.Mount("/", health.Router())

	r.Route("/v1/ai", func(r chi.Router) {
		r.Post("/rank", func(w http.ResponseWriter, r *http.Request) {
			var req rankRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			res := dispatchbrain.Rank(req.Weights, req.Candidates)
			httputil.WriteJSON(w, http.StatusOK, res)
		})

		r.Post("/demand/observe", func(w http.ResponseWriter, r *http.Request) {
			var req demandObserveRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			if req.CityID == "" || req.ZoneID == "" {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			predictor.Observe(req.CityID, req.ZoneID, time.Now().UTC(), req.Count)
			httputil.WriteNoContent(w)
		})

		r.Post("/demand/predict", func(w http.ResponseWriter, r *http.Request) {
			var req demandPredictRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			if req.CityID == "" || req.ZoneID == "" {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			p := predictor.Predict(req.CityID, req.ZoneID, time.Now().UTC())
			httputil.WriteJSON(w, http.StatusOK, map[string]any{"prediction": p})
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

