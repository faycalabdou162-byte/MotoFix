import '../../../../models/feature_models.dart';

abstract class PaymentRepository {
  Stream<List<PaymentModel>> watchCurrentUserPayments({int limit});

  Stream<List<PaymentModel>> watchDriverPayments(String driverId);

  Stream<List<PaymentModel>> watchRecentPayments({int limit});

  Future<String> createPayment({
    required String requestId,
    required int amount,
    required String method,
    required String phone,
    String driverId,
  });

  Future<void> markPaid(String paymentId);

  Future<void> markFailed(String paymentId);
}
