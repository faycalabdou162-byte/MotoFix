# Checklist sécurité (mobile + Firebase)

## Repo / secrets

- Aucun token/secret commité (GitHub tokens, service accounts, clés privées)
- Rotation des secrets exposés historique
- Logs nettoyés (pas de données perso, pas de tokens)

## App

- Écrans privés protégés (auth guards)
- Validation côté client (en plus des rules)
- Stockage local minimal, pas de secrets persistés en clair

## Firestore rules

- Par défaut : deny
- Read/write conditionnés à l’auth et à l’appartenance (`request.auth.uid`)
- Validation des champs (types, valeurs autorisées)
- Pas de wildcard trop permissif sur collections sensibles

