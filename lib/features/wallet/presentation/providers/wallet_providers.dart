import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(
    dataSource: WalletFirebaseDataSource(
      firestore: ref.watch(firebaseFirestoreProvider),
    ),
  );
});

final walletBalanceProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(0);
  return ref.watch(walletRepositoryProvider).watchBalance(user.uid);
});
