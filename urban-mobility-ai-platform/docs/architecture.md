# Architecture — Urban Mobility AI Platform

## Diagram (texte)

Clients
- Mobile Flutter (User + Driver modes)
- Flutter Web Admin

Edge
- API Gateway/BFF (optionnel) ou accès direct aux services via Ingress
- Rate limiting + WAF (Ingress/Nginx)

Identity
- Firebase Auth (source of truth)
- auth-service (exchange Firebase ID token -> internal session token)

Core microservices
- user-service (profiles, preferences, history)
- driver-service (onboarding, disponibilité, vehicle types, driver state writes)
- trip-service (lifecycle trip, source of truth, outbox)
- dispatch-service (matching temps réel, orchestration dispatch)
- payment-service (validation server-side, anti-fraude hooks)
- geo-service (distance/ETA, routing heuristics, geofencing)
- notification-service (FCM)
- analytics-service (event consumers, dashboards, heatmaps)

AI services
- ai-dispatch-brain (ranking, demand prediction, swarm reposition, smart pricing)

Data
- PostgreSQL + PostGIS (core tables, partition par city)
- Redis (geo index, cache, hot keys, session, rate-limits)
- Kafka (event bus: trip.*, driver.*, payment.*, fraud.*)
- Firestore (real-time state exposé au client: trip_state, driver_state contrôlé)

Flow critique (dispatch)
1) Client -> trip-service: create trip (requested)
2) trip-service -> Kafka: trip.requested
3) dispatch-service -> Redis: query drivers nearby + availability
4) dispatch-service -> ai-dispatch-brain: ranking + ETA + pricing
5) dispatch-service -> Firestore: write trip_state for participants
6) dispatch-service -> Kafka: dispatch.offered
7) driver app -> trip-service: accept
8) trip-service -> Kafka: trip.accepted
9) notification-service -> FCM: push updates

## SLO / objectifs

- Dispatch p99 < 100ms (Redis geo + heuristics local, pas d’appel externe bloquant)
- API p99 < 2s côté client
- Disponibilité 99.9% avec HPA + multi-zone

## Africa mode (faible réseau)

- State minimal côté client, sync différée
- Reconnexion robuste (idempotence + retry)
- Payloads compressés, endpoints coarse-grained
- GPS: downsampling + envoi adaptatif selon vitesse/batterie

