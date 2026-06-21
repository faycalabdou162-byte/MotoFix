# Urban Mobility AI Platform

Plateforme multi-services (Moto/Car/Tow) orientée Afrique, architecture event-driven, prête à scaler à 1M+ utilisateurs.

## Services (Go)

- auth-service
- user-service
- driver-service
- trip-service
- dispatch-service
- ai-dispatch-brain
- geo-service
- payment-service
- notification-service
- analytics-service

## Data

- PostgreSQL (core)
- Redis (cache + geo index + state rapide)
- Firestore (real-time state exposé aux clients uniquement)
- Kafka (event bus)

