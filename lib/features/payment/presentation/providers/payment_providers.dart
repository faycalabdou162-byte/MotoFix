import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../models/feature_models.dart';
import '../../data/datasources/payment_firebase_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/payment_usecases.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    dataSource: PaymentFirebaseDataSource(
      firestore: ref.watch(firebaseFirestoreProvider),
      auth: ref.watch(firebaseAuthProvider),
    ),
  );
});

final createPaymentUseCaseProvider = Provider<CreatePaymentUseCase>((ref) {
  return CreatePaymentUseCase(ref.watch(paymentRepositoryProvider));
});

final watchUserPaymentsUseCaseProvider =
    Provider<WatchUserPaymentsUseCase>((ref) {
  return WatchUserPaymentsUseCase(ref.watch(paymentRepositoryProvider));
});

final userPaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(watchUserPaymentsUseCaseProvider).call();
});
