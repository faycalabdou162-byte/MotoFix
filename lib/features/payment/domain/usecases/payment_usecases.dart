import '../../../../models/feature_models.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentUseCase {
  const CreatePaymentUseCase(this._repository);

  final PaymentRepository _repository;

  Future<String> call({
    required String requestId,
    required int amount,
    required String method,
    required String phone,
    String driverId = '',
  }) {
    return _repository.createPayment(
      requestId: requestId,
      amount: amount,
      method: method,
      phone: phone,
      driverId: driverId,
    );
  }
}

class WatchUserPaymentsUseCase {
  const WatchUserPaymentsUseCase(this._repository);

  final PaymentRepository _repository;

  Stream<List<PaymentModel>> call({int limit = 30}) {
    return _repository.watchCurrentUserPayments(limit: limit);
  }
}
