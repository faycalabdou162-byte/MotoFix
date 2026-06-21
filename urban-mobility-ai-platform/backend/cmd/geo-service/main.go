package main

import (
	"context"
	"encoding/json"
	"net/http"
	"os/signal"
	"syscall"

	"github.com/go-chi/chi/v5"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/domain"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/geo"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/config"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/health"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httpserver"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httputil"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/middleware"
)

type etaRequest struct {
	From domain.LatLng `json:"from"`
	To   domain.LatLng `json:"to"`
	Mode string        `json:"mode"`
}

func main() {
	cfg := config.Load("geo-service")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)
	r.Mount("/", health.Router())

	r.Route("/v1/geo", func(r chi.Router) {
		r.Post("/eta", func(w http.ResponseWriter, r *http.Request) {
			var req etaRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			distM := geo.DistanceM(req.From.Lat, req.From.Lng, req.To.Lat, req.To.Lng)
			speedKmh := 25.0
			if req.Mode == "car" {
				speedKmh = 30.0
			}
			if req.Mode == "tow" {
				speedKmh = 20.0
			}
			etaSec := int64((distM / 1000.0) / speedKmh * 3600.0)
			httputil.WriteJSON(w, http.StatusOK, map[string]any{"distanceM": distM, "etaSeconds": etaSec})
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
