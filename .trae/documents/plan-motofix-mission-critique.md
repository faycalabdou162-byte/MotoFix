# Plan — MotoFix “Mission Critique”

## 1) Résumé

Objectif : transformer MotoFix en application Flutter “publishable aujourd’hui” (stable, sécurisée, moderne, performante, évolutive) en respectant strictement un budget nul (Firebase Spark ou alternatives gratuites uniquement).

Ce plan est structuré pour exécuter : audit total → correctifs automatiques → refonte/normalisation architecture → durcissement Firebase/Firestore → upgrade UX premium → optimisation perfs → design system → sécurité → préparation publication + checklists.

## 2) Analyse de l’état actuel (constaté dans l’environnement)

### Codebase
- Le workspace ne contient actuellement que [README.md](file:///workspace/README.md) et le répertoire Git.
- Aucune arborescence Flutter n’est présente (pas de `pubspec.yaml`, `lib/`, `android/`, `ios/`, `web/`), donc **impossible d’auditer/patcher l’app tant que le checkout n’est pas rétabli**.

### Sécurité (P0)
- Le remote Git configuré dans `.git/config` contient un **token d’accès** (secret). Cela constitue un risque critique immédiat : fuite de credential si le repo est partagé, exporté ou loggé.

## 3) Décisions & principes (bloquants, mais déterministes)

### Priorités (ordre strict)
1. Stabilité (crash, analyse statique, build, régressions)
2. Sécurité (auth guards, rules Firestore, secrets)
3. UX (écrans complets, feedback, états vides, loaders)
4. Performance (Firestore reads, listes, startup, rebuilds)
5. Évolutivité (architecture claire, conventions, tests)

### Budget / Firebase
- Interdiction : Cloud Functions obligatoires, Firebase Storage obligatoire, APIs payantes, SMS payants, serveurs payants.
- Autorisé si gratuit Spark : Auth, Firestore, Analytics, Crashlytics, FCM, Remote Config, Performance, App Check (mode debug/dev + prod si supporté).
- Règle : **aucune fonctionnalité ne doit dépendre d’un upgrade Blaze**.

### Choix techniques (règles de sélection après checkout)
- State management :
  - Si un seul système est déjà dominant (≥ 70% des écrans) : on le conserve et on homogénéise.
  - Si coexistence Riverpod/BLoC/Provider sans dominance claire : consolidation vers **Riverpod** (meilleur compromis évolutivité/DI/test).
- Navigation :
  - Si `go_router` existe déjà : on le standardise.
  - Sinon : on reste sur Navigator 1.0 mais avec une couche `AppRouter` centralisée (évite migration risquée).
- Skeleton loaders : sans dépendance payante ; si aucune lib type shimmer n’existe, on implémente un skeleton maison (AnimatedContainer/ShaderMask).

## 4) Livrables (fichiers à produire pendant l’exécution)

- `/workspace/docs/audit_report.md` : rapport complet (P0/P1/P2, architecture, dépendances, sécurité, perfs, UX, Firebase).
- `/workspace/docs/fixes_applied.md` : liste des correctifs appliqués (par commit logique).
- `/workspace/docs/risks_remaining.md` : risques restants + mitigation.
- `/workspace/docs/checklists/` :
  - `publication.md`
  - `play_store.md`
  - `firebase.md`
  - `security.md`
  - `qa.md`
- `/workspace/docs/maturity_score.md` : score avant/après (rubrique détaillée + justification).

## 5) Plan d’exécution détaillé (phases)

### Phase 0 — Rétablir le code (P0 bloquant)
Objectif : obtenir une working tree Flutter complète et sécuriser les credentials Git.

Actions :
1. Diagnostiquer l’état Git (working tree vide) : `git status`, `git sparse-checkout list` (si activé), `git ls-tree` sur HEAD si besoin.
2. Rétablir les fichiers du commit `main` :
   - tenter `git checkout -f main` puis `git reset --hard`.
   - si échec : re-cloner proprement dans `/workspace` (en conservant les livrables dans `/workspace/docs`).
3. Sécuriser le remote :
   - remplacer immédiatement l’URL remote par une URL sans secret.
   - consigner dans le rapport : action requise côté propriétaire du repo = **révoquer/rotater le token** ayant fuité.

Critères de succès :
- `pubspec.yaml` présent.
- `lib/`, `android/`, `ios/` (et éventuellement `web/`) présents.
- `flutter pub get` fonctionne (sans prompts).

### Phase 1 — Audit total (P0/P1/P2) + baseline qualité
Objectif : photographier l’état réel, identifier ce qui bloque la publication, et établir une baseline mesurable.

Actions :
1. Inventaire structurel :
   - cartographier `lib/` (entrypoints, features, services, data layer).
   - repérer navigation, auth guards, gestion d’état, DI, config d’environnements.
2. Dépendances :
   - analyser `pubspec.yaml` (versions, packages obsolètes, doublons, packages lourds, risques sécurité).
3. Qualité Flutter/Dart :
   - `flutter analyze` + correction progressive des lints/erreurs.
   - recherche des `TODO`, `print`, `debugPrint`, logs sensibles.
4. Firebase :
   - vérifier initialisation (`firebase_core`), environnements, `google-services.json` / `GoogleService-Info.plist`, `firebase_options.dart` (si FlutterFire).
   - détecter usage de Firestore (collections, patterns de requêtes, indexes nécessaires).
5. Sécurité :
   - vérifier existence/qualité des Firestore rules (`firestore.rules` ou via `firebase.json`).
   - vérifier auth gating des écrans et des requêtes.
6. Performance :
   - repérer `StreamBuilder`/listeners non paginés, requêtes répétées, rebuilds excessifs.
7. UX/UI :
   - repérer écrans vides, absence d’états (loading/empty/error), incohérences design.

Sorties :
- produire `/workspace/docs/audit_report.md` avec sections : Architecture, Firebase, Sécurité, Performance, UX, Dépendances, P0/P1/P2.
- produire une liste priorisée d’actions “publication today”.

### Phase 2 — Corrections automatiques (sans confirmation)
Objectif : passer de “cassé/instable” à “buildable + navigable + non-crashy”.

Actions (itératives, jusqu’à zéro P0) :
1. Corriger erreurs Dart/Flutter :
   - imports cassés, fichiers manquants, null-safety, types, async/await, futures non gérées.
2. Navigation :
   - routes cassées, deeplinks incohérents, guards auth manquants.
3. Modèles/Firestore :
   - sérialisation robuste (fromJson/toJson), champs optionnels, migrations “soft”.
   - éliminer les lectures redondantes (memoization, pagination, cache local léger).
4. Crashs potentiels :
   - assertions dangereuses, `!` non justifiés, accès liste vide, context misuse.

Critères de succès :
- `flutter analyze` sans erreur.
- `flutter test` passe (ou ajout de tests minimaux pour les zones critiques).
- build Android debug OK.

### Phase 3 — Architecture (réorganisation maîtrisée)
Objectif : structure claire et scalable sans régression.

Décision d’architecture :
- adopter une structure cible :
  - `lib/core/` (errors, network, utils, config, theming primitives)
  - `lib/features/<feature>/` (presentation, application, data)
  - `lib/services/` (wrappers firebase, notifications, analytics)
  - `lib/repositories/` (interfaces + impl)
  - `lib/models/` (domain/value objects partagés)
  - `lib/widgets/` (shared UI)
  - `lib/theme/` (design system)
  - `lib/config/` (env, constants, routing)
- migration progressive “feature-by-feature” :
  - créer des adaptateurs pour éviter un big-bang.

Critères de succès :
- pas de cycles d’import, conventions cohérentes, fichiers localisables rapidement.
- l’app se lance après chaque étape (smoke tests).

### Phase 4 — Firebase/Firestore (sécuriser + optimiser coût)
Objectif : sécurité stricte + minimum reads + compat Spark.

Actions :
1. Auth :
   - imposer `FirebaseAuth` gating pour toute donnée privée.
   - logique de session robuste (refresh, logout, suppression de compte si présent).
2. Firestore rules :
   - écrire/renforcer des rules “deny by default”.
   - accès par userId (documents appartenant à l’utilisateur) + rôles (si existants).
   - validation de schémas minimaux (types, champs obligatoires) pour prévenir injections.
3. Index & requêtes :
   - identifier requêtes nécessitant indexes composites.
   - modifier requêtes pour être index-friendly (orderBy/where compatibles).
4. Observabilité :
   - activer Crashlytics/Analytics/Performance si déjà inclus, sinon ajouter uniquement si utile et gratuit.
5. App Check :
   - activer en mode debug/dev + stratégie prod si supportée sans surcoût.

Critères de succès :
- rules empêchent tout accès non authentifié (sauf collections publiques explicitement listées).
- réduction des streams globaux non paginés.

### Phase 5 — Expérience utilisateur premium
Objectif : aucun écran vide, ressenti “startup financée”.

Actions :
1. États UI systématiques :
   - loading (skeleton), empty states (illustration + action), error states (retry + support).
2. Micro-interactions :
   - transitions, haptic léger, animations de listes (implicit animations).
3. Messages modernes :
   - copywriting court, feedback immédiat (snackbars/toasts), confirmations claires.
4. Parcours :
   - onboarding (valeur + permissions), dashboard (actions rapides), historique (filtrage/tri), profil/paramètres (sécurité, confidentialité).

Critères de succès :
- chaque écran principal a loading/empty/error + primary action.
- navigation fluide, sans latence perceptible sur listes.

### Phase 6 — “Intelligence produit” locale (sans IA cloud)
Objectif : suggestions utiles 100% offline.

Actions :
- scoring local basé sur :
  - récence/fréquence d’actions, préférences, contexte (heure/jour), catégories.
- fonctionnalités :
  - tri intelligent (par pertinence), priorisation (tâches/rdv), quick actions, rappels locaux.
- stockage :
  - persistance locale gratuite (SharedPreferences ou équivalent existant dans le projet).

### Phase 7 — Performances (mesurables)
Objectif : réduire jank, reads Firestore, et temps de démarrage.

Actions :
1. Listes :
   - `ListView.builder`, `SliverList`, itemExtent/caching, keys stables.
2. Rebuilds :
   - séparer widgets, éviter `setState` global, selectors Riverpod si applicable.
3. Firestore :
   - pagination, `limit`, `startAfter`, éviter `snapshots()` sur collections entières.
4. Build size :
   - supprimer deps inutiles, activer R8/proguard (Android), assets optimisés.

### Phase 8 — Design system (futuriste premium africain moderne)
Objectif : cohérence UI totale et composants réutilisables.

Décisions :
- Palette : fond sombre + accents “néon” sobres (or/ambre + cyan/bleu) + surfaces élevées.
- Typo : hiérarchie stricte (Title/Body/Label), tracking léger, contrastes AA.
- Tokens :
  - espacements (4/8/12/16/24/32), rayons (12/16/24), elevations, durations.
- Composants :
  - boutons (primary/secondary/ghost), champs (states), cartes, dialogs, bottom sheets, chips, badges.

Implémentation :
- `ThemeData` central + `ThemeExtension` pour tokens.
- composants partagés dans `lib/theme/` et `lib/widgets/`.

### Phase 9 — Sécurité applicative
Objectif : réduire surface d’attaque et fuites.

Actions :
- supprimer logs sensibles, clés, tokens.
- durcir navigation (routes privées), validation côté client (en plus des rules).
- stockage local : ne jamais stocker tokens sensibles en clair (utiliser solutions existantes si présentes, sinon minimiser le stockage).

### Phase 10 — Publication (Android + checklists)
Objectif : livrer un projet prêt Play Store.

Actions :
- config Android : `applicationId`, versioning, signing (instructions), shrink/obfuscation si safe.
- audit permissions, icônes, splash, nom, screenshots (checklist).
- QA : smoke tests, parcours critiques, offline/poor network, devices.

Sorties :
- checklists dans `/workspace/docs/checklists/`.

## 6) Vérification (à exécuter systématiquement)

À la fin de chaque lot de modifications :
- `flutter clean` (si nécessaire) + `flutter pub get`
- `flutter analyze`
- `flutter test`
- build Android debug + smoke test (lancement, login, navigation principale)

Avant “publishable today” :
- build Android release (sans publication automatique)
- revue Firestore rules (deny-by-default) + sanity check des requêtes
- revue des dépendances (licenses/poids/risques)

## 7) Méthode de scoring maturité (avant/après)

Rubrique (0–5 chacune, total /40) :
1. Stabilité (crash, analyse, tests, builds)
2. Sécurité (rules, auth guards, secrets)
3. Performance (startup, listes, reads)
4. UX (états, cohérence, polish)
5. Architecture (structure, découplage, testabilité)
6. Qualité code (lint, conventions, dette)
7. Observabilité (crash reporting, logs)
8. Publication readiness (configs, checklists)

On calcule “avant” après Phase 1, et “après” après Phase 10.

