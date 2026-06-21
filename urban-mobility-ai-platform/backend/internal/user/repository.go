package user

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

func (r *Repository) Upsert(ctx context.Context, u User) (User, error) {
	if r.db == nil {
		return User{}, errors.New("missing db")
	}
	now := time.Now().UTC()
	u.UpdatedAt = now
	if u.CreatedAt.IsZero() {
		u.CreatedAt = now
	}
	_, err := r.db.Exec(ctx, `
		insert into users (id, city_id, phone, name, created_at, updated_at)
		values ($1,$2,$3,$4,$5,$6)
		on conflict (city_id, id) do update set phone=excluded.phone, name=excluded.name, updated_at=excluded.updated_at
	`, u.ID, u.CityID, u.Phone, u.Name, u.CreatedAt, u.UpdatedAt)
	if err != nil {
		return User{}, err
	}
	return u, nil
}

func (r *Repository) Get(ctx context.Context, cityID, id string) (User, error) {
	if r.db == nil {
		return User{}, errors.New("missing db")
	}
	var u User
	err := r.db.QueryRow(ctx, `
		select id, city_id, phone, name, created_at, updated_at
		from users where city_id=$1 and id=$2
	`, cityID, id).Scan(&u.ID, &u.CityID, &u.Phone, &u.Name, &u.CreatedAt, &u.UpdatedAt)
	return u, err
}

