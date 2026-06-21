package redis

import (
	"context"
	"errors"

	"github.com/redis/go-redis/v9"
)

func Connect(addr, pass string) (*redis.Client, error) {
	if addr == "" {
		return nil, errors.New("missing redis addr")
	}
	c := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: pass,
		DB:       0,
	})
	if err := c.Ping(context.Background()).Err(); err != nil {
		_ = c.Close()
		return nil, err
	}
	return c, nil
}

