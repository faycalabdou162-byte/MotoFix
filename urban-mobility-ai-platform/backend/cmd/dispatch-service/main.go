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

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/dispatchbrain"
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
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/trip"
)

type dispatchOffer struct {
	CityID     string            `json:"cityId"`
	TripID     string            `json:"tripId"`
	DriverID   string            `json:"driverId"`
	Vehicle    domain.VehicleType `json:"vehicleType"`
	Rank       int               `json:"rank"`
	Score      float64           `json:"score"`
	DistanceM  float64           `json:"distanceM"`
	ETASeconds int64             `json:"etaSeconds"`
}

func main() {
	cfg := config.Load("dispatch-service")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	redisClient, err := redisp.Connect(cfg.RedisAddr, cfg.RedisPass)
	if err != nil {
		panic(err)
	}
	defer func() { _ = redisClient.Close() }()

	producer := kafka.NewProducer(cfg.KafkaBrokers, "mobility-events")
	defer func() { _ = producer.Close() }()

	consumer := kafka.NewConsumer(cfg.KafkaBrokers, "dispatch-service", "mobility-events")
	defer func() { _ = consumer.Close() }()

	go runMatchingLoop(ctx, redisClient, consumer, producer)

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)
	r.Mount("/", health.Router())
	r.Get("/v1/dispatch/ping", func(w http.ResponseWriter, r *http.Request) {
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

func runMatchingLoop(ctx context.Context, redisClient *redis.Client, consumer *kafka.Consumer, producer *kafka.Producer) {
	weights := dispatchbrain.ScoringWeights{
		DistanceWeight:     0.45,
		DriverRatingWeight: 0.15,
		AvailabilityWeight: 0.10,
		TrafficWeight:      0.15,
		VehicleMatchWeight: 0.15,
	}

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
		if err := json.Unmarshal(m.Value, &env); err != nil {
			_ = consumer.Commit(ctx, m)
			continue
		}
		if env.EventType != events.EventTripRequested {
			_ = consumer.Commit(ctx, m)
			continue
		}

		var t trip.Trip
		if err := json.Unmarshal(env.Data, &t); err != nil {
			_ = consumer.Commit(ctx, m)
			continue
		}

		offers := matchTrip(ctx, redisClient, weights, t)
		for _, o := range offers {
			env2 := events.EventEnvelope[dispatchOffer]{
				EventID:     newID(),
				EventType:   events.EventDispatchOffered,
				OccurredAt:  time.Now().UTC(),
				CityID:      o.CityID,
				AggregateID: o.TripID,
				Data:        o,
			}
			_ = producer.Write(ctx, o.DriverID, encoding.MustJSON(env2))
		}

		_ = consumer.Commit(ctx, m)
	}
}

func matchTrip(ctx context.Context, redisClient *redis.Client, weights dispatchbrain.ScoringWeights, t trip.Trip) []dispatchOffer {
	geoKey := "driver_geo:" + t.CityID + ":" + string(t.VehicleType)
	availKey := "driver_availability:" + t.CityID

	res, err := redisClient.GeoRadius(ctx, geoKey, t.Pickup.Lng, t.Pickup.Lat, &redis.GeoRadiusQuery{
		Radius:      5,
		Unit:        "km",
		WithDist:    true,
		WithCoord:   true,
		Count:       50,
		Sort:        "ASC",
		StoreDist:   "",
	}).Result()
	if err != nil {
		return nil
	}

	candidates := make([]dispatchbrain.Candidate, 0, len(res))
	for _, r := range res {
		avail, err := redisClient.HGet(ctx, availKey, r.Name).Result()
		if err == nil && avail != "1" {
			continue
		}
		distM := r.Dist * 1000.0
		candidates = append(candidates, dispatchbrain.Candidate{
			DriverID:      r.Name,
			DistanceM:     distM,
			DriverRating:  4.5 / 5.0,
			Availability:  1.0,
			TrafficFactor: 1.2,
			VehicleMatch:  1.0,
		})
	}

	ranked := dispatchbrain.Rank(weights, candidates)
	out := make([]dispatchOffer, 0, len(ranked))
	for i, c := range ranked {
		eta := int64((c.DistanceM / 1000.0) / 20.0 * 3600.0)
		out = append(out, dispatchOffer{
			CityID:     t.CityID,
			TripID:     t.ID,
			DriverID:   c.DriverID,
			Vehicle:    t.VehicleType,
			Rank:       i + 1,
			Score:      c.Score,
			DistanceM:  c.DistanceM,
			ETASeconds: eta,
		})
		if i == 9 {
			break
		}
	}
	return out
}

func newID() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	return hex.EncodeToString(b[:])
}
