import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/payment/data/datasources/payment_firebase_datasource.dart';
import '../features/payment/data/repositories/payment_repository_impl.dart';
import '../features/payment/domain/repositories/payment_repository.dart';

export '../features/payment/domain/repositories/payment_repository.dart'
    show PaymentRepository;

/// Backward-compatible facade — prefer [paymentRepositoryProvider].
class PaymentService extends PaymentRepositoryImpl {
  PaymentService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : super(
          dataSource: PaymentFirebaseDataSource(
            firestore: firestore,
            auth: auth,
          ),
        );
}
