/// Typed errors for consistent UI error handling across services.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

final class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

final class LocationException extends AppException {
  const LocationException(super.message, {super.code});
}

final class PaymentException extends AppException {
  const PaymentException(super.message, {super.code});
}

final class RequestException extends AppException {
  const RequestException(super.message, {super.code});
}

String friendlyError(Object error) {
  if (error is AppException) return error.message;
  if (error is StateError) return error.message;
  return 'Une erreur est survenue. Réessayez.';
}
