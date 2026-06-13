import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firebase_collections.dart';
import '../models/request_model.dart';

class RevenueSummary {
  const RevenueSummary({
    required this.totalRevenue,
    required this.commission,
    required this.availableBalance,
    required this.completedTrips,
  });

  final int totalRevenue;
  final int commission;
  final int availableBalance;
  final int completedTrips;
}

class RevenueService {
  RevenueService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const double commissionRate = .15;

  final FirebaseFirestore _firestore;

  Stream<List<RequestModel>> watchCompletedDriverRequests(String driverId) {
    return _firestore
        .collection(FirebaseCollections.requests)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: RequestStatus.completed)
        .limit(80)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            return RequestModel.fromMap(doc.id, doc.data());
          }).toList();
          requests.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return requests;
        });
  }

  RevenueSummary summarize(List<RequestModel> requests) {
    final total = requests.fold<int>(0, (sum, request) => sum + request.price);
    final commission = (total * commissionRate).round();
    return RevenueSummary(
      totalRevenue: total,
      commission: commission,
      availableBalance: total - commission,
      completedTrips: requests.length,
    );
  }
}
