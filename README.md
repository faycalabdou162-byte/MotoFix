# Urban Mobility AI Platform

Plateforme de mobilité intelligente multi-services, pensée pour l'Afrique francophone et prête pour une montée en charge mondiale.

## Vision

Cette plateforme remplace un monolithe Flutter/Firebase historique par un monorepo de production avec:

- `3 apps Flutter`: `rider_app`, `driver_app`, `admin_web`
- `10 microservices Go` plus `api-gateway`
- `PostgreSQL + PostGIS` comme source de vérité
- `Redis Cluster` pour cache, GEO, locks, idempotence et présence
- `Redpanda / Kafka` pour les flux événementiels
- `Firestore` pour les projections temps réel uniquement
- `Kubernetes` pour le déploiement et l'autoscaling

## Structure

```text
apps/                Clients Flutter
packages/dart/       SDKs et composants partagés
services/            Microservices Go
libs/go/             Bibliothèques communes Go
db/postgres/         Migrations SQL
proto/               Contrats Protobuf
ml/                  Pipelines IA
infra/               Docker, Kubernetes, observabilité
docs/                Architecture, API, runbooks
```

## Services cœur

- `auth-service`
- `user-service`
- `driver-service`
- `trip-service`
- `dispatch-service`
- `ai-dispatch-brain`
- `geo-service`
- `payment-service`
- `notification-service`
- `analytics-service`
- `api-gateway`

## Principes techniques

- `Zero Trust`: auth stricte, RBAC, audit logs, chiffrement PII
- `Event-driven`: chaque service publie et consomme des événements versionnés
- `Low-bandwidth by design`: projections temps réel légères, mode offline, fallback ETA
- `Africa-first`: Mapbox, cash, mobile money, SMS fallback, résilience GPS

## Démarrage

Le dépôt contient les fondations du monorepo. La compilation complète des apps Flutter doit être lancée dans un environnement où `flutter` est installé.

Pour la partie Go:

```bash
go mod tidy
go test ./...
```

## État du dépôt

Le code historique Flutter à la racine est conservé comme référence de migration. Les nouvelles implémentations de production vivent dans `apps/`, `services/`, `libs/`, `db/`, `proto/` et `infra/`.
