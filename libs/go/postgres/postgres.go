package postgres

import (
	"context"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
)

func NewPool(ctx context.Context) (*pgxpool.Pool, error) {
	dsn := os.Getenv("POSTGRES_DSN")
	if dsn == "" {
		dsn = "postgres://postgres:postgres@localhost:5432/urban_mobility?sslmode=disable"
	}
	return pgxpool.New(ctx, dsn)
}
