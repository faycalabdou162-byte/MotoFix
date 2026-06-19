import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletFirebaseDataSource {
  WalletFirebaseDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _wallet(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection('wallet')
        .doc('balance');
  }

  Stream<int> watchBalance(String userId) {
    return _wallet(userId).snapshots().map((doc) {
      final balance = doc.data()?['amount'];
      if (balance is int) return balance;
      if (balance is num) return balance.round();
      return 0;
    });
  }

  Future<int> fetchBalance(String userId) async {
    final doc = await _wallet(userId).get();
    final balance = doc.data()?['amount'];
    if (balance is int) return balance;
    if (balance is num) return balance.round();
    return 0;
  }
}

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({WalletFirebaseDataSource? dataSource})
      : _dataSource = dataSource ?? WalletFirebaseDataSource();

  final WalletFirebaseDataSource _dataSource;

  @override
  Future<int> fetchBalance(String userId) =>
      _dataSource.fetchBalance(userId);

  @override
  Stream<int> watchBalance(String userId) =>
      _dataSource.watchBalance(userId);
}
