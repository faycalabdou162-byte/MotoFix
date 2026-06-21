module github.com/urbanmobilityai/platform

go 1.25.0

require (
	cloud.google.com/go/firestore v1.18.0
	github.com/IBM/sarama v1.45.1
	github.com/go-chi/chi/v5 v5.2.1
	github.com/go-chi/httprate v0.14.1
	github.com/go-playground/validator/v10 v10.25.0
	github.com/golang-jwt/jwt/v5 v5.2.2
	github.com/google/uuid v1.6.0
	github.com/jackc/pgx/v5 v5.7.5
	github.com/redis/go-redis/v9 v9.8.0
	go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp v0.60.0
	go.opentelemetry.io/otel v1.35.0
	go.opentelemetry.io/otel/exporters/stdout/stdouttrace v1.35.0
	go.opentelemetry.io/otel/sdk v1.35.0
	google.golang.org/api v0.226.0
)
