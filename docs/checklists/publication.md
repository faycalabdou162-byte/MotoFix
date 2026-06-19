# Checklist publication (générale)

## Flutter

- `flutter analyze` sans erreur
- `flutter test` passe (tests unitaires + smoke tests)
- Build Android release OK (`flutter build appbundle` ou `flutter build apk --release`)
- Splash screen + icône app configurés
- Versioning cohérent (versionName/versionCode)

## Qualité

- Aucun crash connu sur parcours critiques
- Gestion offline / réseau lent (states + retries)
- Aucune fuite de secrets (tokens, clés privées, endpoints internes)

