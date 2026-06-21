package config

import "os"

type Gateway struct {
	InternalJWTIssuer string
	RateLimitRPM      int
}

func Load() Gateway {
	issuer := os.Getenv("JWT_ISSUER")
	if issuer == "" {
		issuer = "urban-mobility-ai"
	}

	return Gateway{
		InternalJWTIssuer: issuer,
		RateLimitRPM:      120,
	}
}
