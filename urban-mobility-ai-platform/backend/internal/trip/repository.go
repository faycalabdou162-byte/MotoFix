package trip

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(ctx context.Context, t Trip) (Trip, error) {
	if r.db == nil {
		return Trip{}, errors.New("missing db")
	}
	now := time.Now().UTC()
	t.CreatedAt = now
	t.UpdatedAt = now
	_, err := r.db.Exec(ctx, `
		insert into trips (id, city_id, user_id, driver_id, vehicle_type, status, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, created_at, updated_at, surge_factor, quoted_currency, quoted_amount)
		values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
	`, t.ID, t.CityID, t.UserID, t.DriverID, t.VehicleType, t.Status, t.Pickup.Lat, t.Pickup.Lng, t.Dropoff.Lat, t.Dropoff.Lng, t.CreatedAt, t.UpdatedAt, t.SurgeFactor, t.QuotedPrice.Currency, t.QuotedPrice.Amount)
	if err != nil {
		return Trip{}, err
	}
	return t, nil
}

func (r *Repository) UpdateStatus(ctx context.Context, cityID, tripID string, status string, driverID string) error {
	if r.db == nil {
		return errors.New("missing db")
	}
	_, err := r.db.Exec(ctx, `
		update trips set status=$1, driver_id=coalesce(nullif($2,''), driver_id), updated_at=now()
		where city_id=$3 and id=$4
	`, status, driverID, cityID, tripID)
	return err
}

