package main

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/domain"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/events"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/config"
	fb "github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/firebase"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/health"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httpserver"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httputil"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/kafka"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/middleware"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/postgres"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/encoding"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/trip"
)

type createTripRequest struct {
	CityID      string            `json:"cityId"`
	VehicleType domain.VehicleType `json:"vehicleType"`
	Pickup      domain.LatLng      `json:"pickup"`
	Dropoff     domain.LatLng      `json:"dropoff"`
	Currency    string            `json:"currency"`
	QuotedAmount int64            `json:"quotedAmount"`
	SurgeFactor float64           `json:"surgeFactor"`
}

type acceptTripRequest struct {
	CityID   string `json:"cityId"`
	TripID   string `json:"tripId"`
	DriverID string `json:"driverId"`
}

func main() {
	cfg := config.Load("trip-service")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	db, err := postgres.Connect(ctx, cfg.PostgresURL)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	var creds []byte
	if b64 := os.Getenv("FIREBASE_ADMIN_CREDENTIALS_B64"); b64 != "" {
		decoded, err := base64.StdEncoding.DecodeString(b64)
		if err == nil {
			creds = decoded
		}
	}
	verifier, err := fb.NewAuthVerifier(ctx, cfg.FirebaseProjectID, creds)
	if err != nil {
		panic(err)
	}

	repo := trip.NewRepository(db)
	producer := kafka.NewProducer(cfg.KafkaBrokers, "mobility-events")
	defer func() { _ = producer.Close() }()

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)
	r.Mount("/", health.Router())

	r.Route("/v1/trips", func(r chi.Router) {
		r.Use(middleware.FirebaseAuth(verifier))

		r.Post("/", func(w http.ResponseWriter, r *http.Request) {
			var req createTripRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			if req.CityID == "" || req.VehicleType == "" {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			tok, ok := middleware.FirebaseTokenFromContext(r.Context())
			if !ok {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}

			t := trip.Trip{
				ID:          newID(),
				CityID:      req.CityID,
				UserID:      tok.UID,
				VehicleType: req.VehicleType,
				Status:      domain.TripRequested,
				Pickup:      req.Pickup,
				Dropoff:     req.Dropoff,
				SurgeFactor: req.SurgeFactor,
				QuotedPrice: domain.Money{Currency: req.Currency, Amount: req.QuotedAmount},
			}
			created, err := repo.Create(r.Context(), t)
			if err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}

			env := events.EventEnvelope[trip.Trip]{
				EventID:     newID(),
				EventType:   events.EventTripRequested,
				OccurredAt:  time.Now().UTC(),
				CityID:      created.CityID,
				AggregateID: created.ID,
				Data:        created,
			}
			_ = producer.Write(r.Context(), created.ID, encoding.MustJSON(env))

			httputil.WriteJSON(w, http.StatusCreated, created)
		})

		r.Post("/accept", func(w http.ResponseWriter, r *http.Request) {
			var req acceptTripRequest
			if err := decodeJSON(r, &req); err != nil {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			if req.CityID == "" || req.TripID == "" || req.DriverID == "" {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			if err := repo.UpdateStatus(r.Context(), req.CityID, req.TripID, string(domain.TripAccepted), req.DriverID); err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}

			env := events.EventEnvelope[acceptTripRequest]{
				EventID:     newID(),
				EventType:   events.EventTripAccepted,
				OccurredAt:  time.Now().UTC(),
				CityID:      req.CityID,
				AggregateID: req.TripID,
				Data:        req,
			}
			_ = producer.Write(r.Context(), req.TripID, encoding.MustJSON(env))

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

