import '../../../../models/feature_models.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_firebase_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({PaymentFirebaseDataSource? dataSource})
      : _dataSource = dataSource ?? PaymentFirebaseDataSource();

  final PaymentFirebaseDataSource _dataSource;

  @override
  Stream<List<PaymentModel>> watchCurrentUserPayments({int limit = 30}) {
    final uid = _dataSource.currentUid ?? '_';
    return _dataSource.watchUserPayments(uid, limit: limit);
  }

  @override
  Stream<List<PaymentModel>> watchDriverPayments(String driverId) {
    return _dataSource.watchDriverPayments(driverId);
  }

  @override
  Stream<List<PaymentModel>> watchRecentPayments({int limit = 40}) {
    return _dataSource.watchRecentPayments(limit: limit);
  }

  @override
  Future<String> createPayment({
    required String requestId,
    required int amount,
    required String method,
    required String phone,
    String driverId = '',
  }) async {
    final uid = _dataSource.currentUid;
    if (uid == null) throw StateError('Utilisateur non connecte');
    if (!PaymentMethod.all.contains(method)) {
      throw ArgumentError.value(method, 'method', 'Methode invalide');
    }
    return _dataSource.createPayment(
      userId: uid,
      requestId: requestId,
      amount: amount,
      method: method,
      phone: phone,
      driverId: driverId,
    );
  }

  @override
  Future<void> markPaid(String paymentId) {
    return _dataSource.updateStatus(paymentId, PaymentStatus.paid);
  }

  @override
  Future<void> markFailed(String paymentId) {
    return _dataSource.updateStatus(paymentId, PaymentStatus.failed);
  }
}
