package config

import (
	"os"
	"strconv"
	"time"
)

type App struct {
	Name        string
	Environment string
	Port        int
	ReadTimeout time.Duration
}

func Load(serviceName string, defaultPort int) App {
	return App{
		Name:        serviceName,
		Environment: getString("APP_ENV", "development"),
		Port:        getInt("APP_PORT", defaultPort),
		ReadTimeout: getDuration("APP_READ_TIMEOUT", 10*time.Second),
	}
}

func getString(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func getInt(key string, fallback int) int {
	if value := os.Getenv(key); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil {
			return parsed
		}
	}
	return fallback
}

func getDuration(key string, fallback time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if parsed, err := time.ParseDuration(value); err == nil {
			return parsed
		}
	}
	return fallback
}
