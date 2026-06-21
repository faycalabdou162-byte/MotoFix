package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	fbauth "firebase.google.com/go/v4/auth"
	"github.com/go-chi/chi/v5"
	"github.com/redis/go-redis/v9"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/config"
	fb "github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/firebase"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/health"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/httpserver"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/jwt"
	"github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/middleware"
	redisp "github.com/motofix/urban-mobility-ai-platform/backend/internal/platform/redis"
)

type upstreams struct {
	Auth         *url.URL
	User         *url.URL
	Driver       *url.URL
	Trip         *url.URL
	Dispatch     *url.URL
	AI           *url.URL
	Geo          *url.URL
	Payment      *url.URL
	Notification *url.URL
	Analytics    *url.URL
}

func main() {
	cfg := config.Load("api-gateway")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	ups := upstreams{
		Auth:         mustURL(env("AUTH_SERVICE_URL", "http://auth-service")),
		User:         mustURL(env("USER_SERVICE_URL", "http://user-service")),
		Driver:       mustURL(env("DRIVER_SERVICE_URL", "http://driver-service")),
		Trip:         mustURL(env("TRIP_SERVICE_URL", "http://trip-service")),
		Dispatch:     mustURL(env("DISPATCH_SERVICE_URL", "http://dispatch-service")),
		AI:           mustURL(env("AI_SERVICE_URL", "http://ai-dispatch-brain")),
		Geo:          mustURL(env("GEO_SERVICE_URL", "http://geo-service")),
		Payment:      mustURL(env("PAYMENT_SERVICE_URL", "http://payment-service")),
		Notification: mustURL(env("NOTIFICATION_SERVICE_URL", "http://notification-service")),
		Analytics:    mustURL(env("ANALYTICS_SERVICE_URL", "http://analytics-service")),
	}

	redisClient, err := redisp.Connect(cfg.RedisAddr, cfg.RedisPass)
	if err != nil {
		panic(err)
	}
	defer func() { _ = redisClient.Close() }()

	var creds []byte
	if b64 := os.Getenv("FIREBASE_ADMIN_CREDENTIALS_B64"); b64 != "" {
		decoded, err := base64.StdEncoding.DecodeString(b64)
		if err == nil {
			creds = decoded
		}
	}
	verifier, err := fb.NewAuthVerifier(ctx, cfg.FirebaseProjectID, creds)
	if err != nil {
		panic(err)
	}

	client := &http.Client{Timeout: 5 * time.Second}

	r := chi.NewRouter()
	r.Use(middleware.Recover)
	r.Use(middleware.RequestID)
	r.Mount("/", health.Router())

	r.Route("/v1", func(r chi.Router) {
		r.Mount("/auth", proxyPrefix(client, redisClient, cfg, verifier, ups.Auth, "/v1/auth", authBypass(), ""))

		r.Mount("/users", proxyPrefix(client, redisClient, cfg, verifier, ups.User, "/v1/users", requireAuth(), ""))
		r.Mount("/drivers", proxyPrefix(client, redisClient, cfg, verifier, ups.Driver, "/v1/drivers", requireAuth(), ""))
		r.Mount("/trips", proxyPrefix(client, redisClient, cfg, verifier, ups.Trip, "/v1/trips", requireAuth(), ""))
		r.Mount("/dispatch", proxyPrefix(client, redisClient, cfg, verifier, ups.Dispatch, "/v1/dispatch", requireAuth(), "admin"))
		r.Mount("/ai", proxyPrefix(client, redisClient, cfg, verifier, ups.AI, "/v1/ai", requireAuth(), "admin"))
		r.Mount("/geo", proxyPrefix(client, redisClient, cfg, verifier, ups.Geo, "/v1/geo", requireAuth(), ""))
		r.Mount("/payments", proxyPrefix(client, redisClient, cfg, verifier, ups.Payment, "/v1/payments", requireAuth(), ""))
		r.Mount("/notifications", proxyPrefix(client, redisClient, cfg, verifier, ups.Notification, "/v1/notifications", requireAuth(), "admin"))
		r.Mount("/analytics", proxyPrefix(client, redisClient, cfg, verifier, ups.Analytics, "/v1/analytics", requireAuth(), "admin"))
	})

	srv := httpserver.New(cfg.HTTPAddr, r)
	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
		defer cancel()
		_ = srv.Shutdown(shutdownCtx)
	}()

	if err := srv.ListenAndServe(ctx); err != nil && err != context.Canceled {
		panic(err)
	}
}

type authMode int

const (
	modeAuthBypass authMode = iota
	modeRequireAuth
)

func authBypass() authMode { return modeAuthBypass }
func requireAuth() authMode { return modeRequireAuth }

func proxyPrefix(client *http.Client, redisClient redisClient, cfg config.Config, verifier fbAuthVerifier, upstream *url.URL, prefix string, mode authMode, requiredRole string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "" || !strings.HasPrefix(r.URL.Path, prefix) {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		if r.ContentLength > 2<<20 {
			w.WriteHeader(http.StatusRequestEntityTooLarge)
			return
		}

		authHeader := r.Header.Get("Authorization")
		var internalToken string
		var role string
		if mode == modeRequireAuth {
			tok, err := verifyFirebase(r.Context(), verifier, authHeader)
			if err != nil {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			claims := jwt.InternalClaims{
				Subject:   tok.UID,
				Role:      stringClaim(tok, "role", "user"),
				CityID:    cityFromRequest(r),
				ActorType: stringClaim(tok, "actorType", "user"),
			}
			if claims.CityID == "" {
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			t, err := jwt.SignInternal(cfg.InternalJWTSecret, claims)
			if err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			internalToken = t
			role = claims.Role
			if requiredRole != "" && role != requiredRole {
				w.WriteHeader(http.StatusForbidden)
				return
			}
		}

		if mode == modeRequireAuth {
			if !rateLimit(redisClient, "rl:"+hashKey(internalToken)+":"+r.URL.Path, 30, time.Second) {
				w.WriteHeader(http.StatusTooManyRequests)
				return
			}
		}

		idemKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
		if idemKey != "" && (r.Method == http.MethodPost || r.Method == http.MethodPut || r.Method == http.MethodPatch) && mode == modeRequireAuth {
			cacheKey := "idem:" + hashKey(internalToken) + ":" + r.Method + ":" + r.URL.Path + ":" + idemKey
			if b, ok := redisGet(redisClient, cacheKey); ok {
				var cached cachedResponse
				if err := json.Unmarshal(b, &cached); err == nil {
					writeCached(w, cached)
					return
				}
			}
			resp, body, err := forward(client, upstream, r, internalToken, authHeader)
			if err != nil {
				w.WriteHeader(http.StatusBadGateway)
				return
			}
			writeUpstream(w, resp, body)
			if resp.StatusCode < 500 {
				_ = redisSet(redisClient, cacheKey, mustJSON(cachedResponse{Status: resp.StatusCode, ContentType: resp.Header.Get("Content-Type"), Body: body}), 24*time.Hour)
			}
			return
		}

		resp, body, err := forward(client, upstream, r, internalToken, authHeader)
		if err != nil {
			w.WriteHeader(http.StatusBadGateway)
			return
		}
		writeUpstream(w, resp, body)
	})
}

type fbAuthVerifier interface {
	VerifyIDToken(ctx context.Context, idToken string) (*fbauth.Token, error)
}

type redisClient interface {
	Get(ctx context.Context, key string) *redis.StringCmd
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) *redis.StatusCmd
	Incr(ctx context.Context, key string) *redis.IntCmd
	Expire(ctx context.Context, key string, expiration time.Duration) *redis.BoolCmd
}

type cachedResponse struct {
	Status      int    `json:"status"`
	ContentType string `json:"contentType"`
	Body        []byte `json:"body"`
}

func writeCached(w http.ResponseWriter, c cachedResponse) {
	if c.ContentType != "" {
		w.Header().Set("Content-Type", c.ContentType)
	}
	w.WriteHeader(c.Status)
	_, _ = w.Write(c.Body)
}

func writeUpstream(w http.ResponseWriter, resp *http.Response, body []byte) {
	ct := resp.Header.Get("Content-Type")
	if ct != "" {
		w.Header().Set("Content-Type", ct)
	}
	w.WriteHeader(resp.StatusCode)
	_, _ = w.Write(body)
}

func forward(client *http.Client, upstream *url.URL, r *http.Request, internalToken string, originalAuth string) (*http.Response, []byte, error) {
	target := *upstream
	target.Path = r.URL.Path
	target.RawQuery = r.URL.RawQuery

	var bodyBytes []byte
	if r.Body != nil {
		b, err := io.ReadAll(io.LimitReader(r.Body, 2<<20))
		if err != nil {
			return nil, nil, err
		}
		bodyBytes = b
	}
	req, err := http.NewRequestWithContext(r.Context(), r.Method, target.String(), bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, nil, err
	}

	req.Header.Set("X-Request-Id", r.Header.Get("X-Request-Id"))
	if ct := r.Header.Get("Content-Type"); ct != "" {
		req.Header.Set("Content-Type", ct)
	}

	if internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+internalToken)
	}
	if internalToken == "" && originalAuth != "" {
		req.Header.Set("Authorization", originalAuth)
	}

	resp, err := client.Do(req)
	if err != nil {
		return nil, nil, err
	}
	defer resp.Body.Close()
	b, err := io.ReadAll(io.LimitReader(resp.Body, 2<<20))
	if err != nil {
		return nil, nil, err
	}
	return resp, b, nil
}

func verifyFirebase(ctx context.Context, verifier fbAuthVerifier, authHeader string) (*fbauth.Token, error) {
	if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
		return nil, http.ErrNoCookie
	}
	idToken := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
	return verifier.VerifyIDToken(ctx, idToken)
}

func stringClaim(tok *fbauth.Token, k, def string) string {
	if tok == nil {
		return def
	}
	v, ok := tok.Claims[k]
	if !ok {
		return def
	}
	s, ok := v.(string)
	if !ok || s == "" {
		return def
	}
	return s
}

func cityFromRequest(r *http.Request) string {
	if v := strings.TrimSpace(r.Header.Get("X-City-Id")); v != "" {
		return v
	}
	if v := strings.TrimSpace(r.URL.Query().Get("cityId")); v != "" {
		return v
	}
	return ""
}

func rateLimit(redisClient redisClient, key string, limit int64, window time.Duration) bool {
	ctx := context.Background()
	n := redisClient.Incr(ctx, key).Val()
	if n == 1 {
		_ = redisClient.Expire(ctx, key, window).Err()
	}
	return n <= limit
}

func redisGet(c redisClient, key string) ([]byte, bool) {
	v, err := c.Get(context.Background(), key).Bytes()
	if err != nil {
		return nil, false
	}
	return v, true
}

func redisSet(c redisClient, key string, value []byte, ttl time.Duration) error {
	return c.Set(context.Background(), key, value, ttl).Err()
}

func hashKey(s string) string {
	h := sha256.Sum256([]byte(s))
	return hex.EncodeToString(h[:])
}

func mustJSON(v any) []byte {
	b, err := json.Marshal(v)
	if err != nil {
		panic(err)
	}
	return b
}

func mustURL(v string) *url.URL {
	u, err := url.Parse(v)
	if err != nil {
		panic(err)
	}
	return u
}

func env(k, def string) string {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	return v
}
