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
	"github.com/redis/go-redis/v9"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/domain"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/events"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/config"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/health"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httpserver"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httputil"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/kafka"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/middleware"
	redisp "github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/redis"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/encoding"
)

type availabilityRequest struct {
	CityID     string            `json:"cityId"`
	DriverID   string            `json:"driverId"`
	Available  bool              `json:"available"`
	Vehicle    domain.VehicleType `json:"vehicleType"`
	Timestamp  time.Time         `json:"timestamp"`
}

type locationRequest struct {
	CityID     string            `json:"cityId"`
	DriverID   string            `json:"driverId"`
	Vehicle    domain.VehicleType `json:"vehicleType"`
	Location   domain.LatLng      `json:"location"`
	Timestamp  time.Time         `json:"timestamp"`
}

func main() {
	cfg := config.Load("driver-service")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	redisClient, err := redisp.Connect(cfg.RedisAddr, cfg.RedisPass)
	if err != nil {
		panic(err)
	}
	defer func() { _ = redisClient.Close() }()

	producer := kafka.NewProducer(cfg.KafkaBrokers, "mobility-events")
	defer func() { _ = producer.Close() }()

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)
	r.Mount("/", health.Router())

	r.Route("/v1/drivers", func(r chi.Router) {
		r.Use(middleware.InternalAuth(cfg.InternalJWTSecret))

		r.Post("/availability", func(w http.ResponseWriter, r *http.Request) {
			var req availabilityRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			if req.CityID == "" || req.DriverID == "" || req.Vehicle == "" {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			claims, ok := middleware.InternalClaimsFromContext(r.Context())
			if !ok {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			if claims.Role != "driver" || claims.CityID != req.CityID || claims.Subject != req.DriverID {
				w.WriteHeader(http.StatusForbidden)
				return
			}
			if req.Timestamp.IsZero() {
				req.Timestamp = time.Now().UTC()
			}

			key := "driver_availability:" + req.CityID
			val := "0"
			if req.Available {
				val = "1"
			}
			if err := redisClient.HSet(r.Context(), key, req.DriverID, val).Err(); err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}

			env := events.EventEnvelope[availabilityRequest]{
				EventID:     newID(),
				EventType:   events.EventDriverAvailability,
				OccurredAt:  time.Now().UTC(),
				CityID:      req.CityID,
				AggregateID: req.DriverID,
				Data:        req,
			}
			_ = producer.Write(r.Context(), req.DriverID, encoding.MustJSON(env))

			httputil.WriteNoContent(w)
		})

		r.Post("/location", func(w http.ResponseWriter, r *http.Request) {
			var req locationRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			if req.CityID == "" || req.DriverID == "" || req.Vehicle == "" {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			claims, ok := middleware.InternalClaimsFromContext(r.Context())
			if !ok {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			if claims.Role != "driver" || claims.CityID != req.CityID || claims.Subject != req.DriverID {
				w.WriteHeader(http.StatusForbidden)
				return
			}
			if req.Timestamp.IsZero() {
				req.Timestamp = time.Now().UTC()
			}

			geoKey := "driver_geo:" + req.CityID + ":" + string(req.Vehicle)
			if err := redisClient.GeoAdd(r.Context(), geoKey, &redis.GeoLocation{
				Name:      req.DriverID,
				Longitude: req.Location.Lng,
				Latitude:  req.Location.Lat,
			}).Err(); err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}

			env := events.EventEnvelope[locationRequest]{
				EventID:     newID(),
				EventType:   events.EventDriverLocation,
				OccurredAt:  time.Now().UTC(),
				CityID:      req.CityID,
				AggregateID: req.DriverID,
				Data:        req,
			}
			_ = producer.Write(r.Context(), req.DriverID, encoding.MustJSON(env))

			httputil.WriteNoContent(w)
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
