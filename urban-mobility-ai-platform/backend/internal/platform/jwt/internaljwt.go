package jwt

import (
	"errors"
	"time"

	jwtlib "github.com/golang-jwt/jwt/v5"
)

type InternalClaims struct {
	Subject   string `json:"sub"`
	Role      string `json:"role"`
	CityID    string `json:"cityId"`
	ActorType string `json:"actorType"`
	jwtlib.RegisteredClaims
}

func SignInternal(secret string, claims InternalClaims) (string, error) {
	if secret == "" {
		return "", errors.New("missing internal jwt secret")
	}
	if claims.ExpiresAt == nil {
		claims.ExpiresAt = jwtlib.NewNumericDate(time.Now().Add(15 * time.Minute))
	}
	t := jwtlib.NewWithClaims(jwtlib.SigningMethodHS256, claims)
	return t.SignedString([]byte(secret))
}

func VerifyInternal(secret, token string) (InternalClaims, error) {
	var out InternalClaims
	if secret == "" {
		return out, errors.New("missing internal jwt secret")
	}
	parsed, err := jwtlib.ParseWithClaims(token, &out, func(t *jwtlib.Token) (any, error) {
		return []byte(secret), nil
	})
	if err != nil {
		return out, err
	}
	if !parsed.Valid {
		return out, errors.New("invalid token")
	}
	return out, nil
}

