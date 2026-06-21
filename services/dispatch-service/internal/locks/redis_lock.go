package locks

import (
	"context"
	"time"

	"github.com/redis/go-redis/v9"
)

func AcquireTripLock(ctx context.Context, client *redis.Client, tripID string, ttl time.Duration) (bool, error) {
	return client.SetNX(ctx, "dispatch:lock:"+tripID, "locked", ttl).Result()
}
