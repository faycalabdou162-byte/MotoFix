import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/repositories/rewards_repository_impl.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepositoryImpl(
    dataSource: RewardsFirebaseDataSource(
      firestore: ref.watch(firebaseFirestoreProvider),
    ),
  );
});

final rewardsPointsProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return 0;
  return ref.watch(rewardsRepositoryProvider).fetchPoints(user.uid);
});
