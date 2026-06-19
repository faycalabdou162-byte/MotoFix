# Checklist Firebase (Spark / gratuit)

## Projet

- Firebase project créé et lié à l’app (Android/iOS)
- Config FlutterFire ou fichiers natifs présents :
  - `firebase_options.dart` (si FlutterFire)
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

## Services (si utilisés)

- Auth : providers configurés + règles de session
- Firestore : règles “deny by default” + indexes nécessaires
- Crashlytics : activé (release) et vérifié via un crash test contrôlé
- Analytics : activé (si besoin produit)
- FCM : notifications testées (foreground/background)
- Remote Config : valeurs par défaut + fetch throttling
- Performance : activé (si utile)
- App Check : mode debug/dev + stratégie prod

## Coût

- Pagination Firestore sur listes (pas de streams globaux)
- Requêtes index-friendly (where/orderBy compatibles)
- Limiter les listeners temps réel aux écrans visibles

