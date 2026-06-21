library auth_sdk;

class SessionExchangeRequest {
  const SessionExchangeRequest({required this.firebaseIdToken});

  final String firebaseIdToken;
}
