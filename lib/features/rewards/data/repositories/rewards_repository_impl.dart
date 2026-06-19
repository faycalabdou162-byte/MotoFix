import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../domain/repositories/rewards_repository.dart';

class RewardsFirebaseDataSource {
  RewardsFirebaseDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _rewards(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection('rewards')
        .doc('summary');
  }

  Future<int> fetchPoints(String userId) async {
    final doc = await _rewards(userId).get();
    final points = doc.data()?['points'];
    if (points is int) return points;
    if (points is num) return points.round();
    return 0;
  }
}

class RewardsRepositoryImpl implements RewardsRepository {
  RewardsRepositoryImpl({RewardsFirebaseDataSource? dataSource})
      : _dataSource = dataSource ?? RewardsFirebaseDataSource();

  final RewardsFirebaseDataSource _dataSource;

  @override
  Future<int> fetchPoints(String userId) => _dataSource.fetchPoints(userId);
}
