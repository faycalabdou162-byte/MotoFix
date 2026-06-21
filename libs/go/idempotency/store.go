package idempotency

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

type Store struct {
	client *redis.Client
	ttl    time.Duration
}

func NewStore(client *redis.Client, ttl time.Duration) Store {
	return Store{client: client, ttl: ttl}
}

func (s Store) Reserve(ctx context.Context, scope, key string) (bool, error) {
	redisKey := fmt.Sprintf("idempotency:%s:%s", scope, key)
	return s.client.SetNX(ctx, redisKey, "reserved", s.ttl).Result()
}
