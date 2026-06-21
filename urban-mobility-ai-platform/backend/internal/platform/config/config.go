package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	ServiceName string
	HTTPAddr    string

	PostgresURL string
	RedisAddr   string
	RedisPass   string
	KafkaBrokers []string

	InternalJWTSecret string

	FirebaseProjectID string

	ShutdownTimeout time.Duration
}

func Load(serviceName string) Config {
	return Config{
		ServiceName:        serviceName,
		HTTPAddr:          env("HTTP_ADDR", ":8080"),
		PostgresURL:       env("POSTGRES_URL", ""),
		RedisAddr:         env("REDIS_ADDR", ""),
		RedisPass:         env("REDIS_PASS", ""),
		KafkaBrokers:      envCSV("KAFKA_BROKERS", ""),
		InternalJWTSecret: env("INTERNAL_JWT_SECRET", ""),
		FirebaseProjectID: env("FIREBASE_PROJECT_ID", ""),
		ShutdownTimeout:   envDuration("SHUTDOWN_TIMEOUT", 10*time.Second),
	}
}

func env(k, def string) string {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	return v
}

func envCSV(k, def string) []string {
	v := os.Getenv(k)
	if v == "" {
		v = def
	}
	if v == "" {
		return nil
	}
	var out []string
	start := 0
	for i := 0; i <= len(v); i++ {
		if i == len(v) || v[i] == ',' {
			if i > start {
				out = append(out, v[start:i])
			}
			start = i + 1
		}
	}
	return out
}

func envDuration(k string, def time.Duration) time.Duration {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		return def
	}
	return d
}

func envInt(k string, def int) int {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return def
	}
	return n
}

