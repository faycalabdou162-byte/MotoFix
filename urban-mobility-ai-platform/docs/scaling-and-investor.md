# Scaling plan (1M users) + pitch technique

## Pourquoi cette architecture peut scaler à 1M+ users

- Partition logique par city dès le modèle de données (`city_id` partout) + partitions Postgres par ville.
- Event bus Kafka comme colonne vertébrale pour découpler la vitesse du temps réel (dispatch) et le reste (analytics, fraud, notifications).
- Redis comme couche “hot path” pour le dispatch : geo-index + disponibilité + caches (latence << DB).
- Firestore limité au temps réel exposé aux clients (trip_state), le “source of truth” reste Postgres.
- Microservices horizontaux sur Kubernetes + HPA + canary.

## Latence dispatch <100ms (p99)

Chemin critique :
- lecture Redis (GEO) + lecture HSET availability + scoring local
- aucune query Postgres dans le hot path
- aucune dépendance API externe

Optimisations :
- prefetch supply/demand par zone (Redis)
- precompute hotspots et reposition (AI brain) en background
- contraintes d’atomicité : claims de driver via Redis Lua ou Redlock

## Stratégie data

- Postgres : transactions, intégrité, outbox pattern (évite double write).
- Kafka : replay, consumers idempotents, DLQ.
- Firestore : états temps réel sous règles strictes, pas de données sensibles.

## Sécurité enterprise

- Zero trust réseau : mTLS service-to-service (service mesh) + JWT interne court.
- Validation inputs (JSON strict + limites taille).
- Rate limiting (Redis) par IP + UID + device fingerprint.
- Audit logs complets (actions sensibles).
- PII chiffrées applicativement (ciphertext + hash pour lookup).
- Paiement : validation server-side uniquement + anti-replay + idempotency keys.

## Anti-fraude (baseline)

Signals :
- multi-comptes, device sharing, patterns d’annulation, anomalies géoloc, mismatch driver/vehicle.
- scoring fraud (fraud-service futur) alimenté par Kafka.
- actions : lock account, step-up verification, cooldown, manual review admin.

## Observabilité

- Logs structurés + correlation id (X-Request-Id)
- Metrics (Prometheus) : latences, taux d’acceptation, supply/demand
- Tracing (OTel) : dispatch path

## Déploiement

- Docker par service (build arg SERVICE)
- Kubernetes manifests (base) + Secret management
- Ingress (NGINX) + cert-manager

## Explication investisseur (1 phrase)

Urban Mobility AI Platform est une plateforme de mobilité multi-services conçue “Afrique-first” : temps réel sur Firestore, transactions sur Postgres, dispatch ultra-rapide via Redis, orchestration event-driven via Kafka, et IA locale évolutive pour réduire le temps d’attente et optimiser l’offre.

