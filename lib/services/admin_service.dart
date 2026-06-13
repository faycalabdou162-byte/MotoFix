import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/request_model.dart';
import '../models/user_model.dart';

class AdminStats {
  const AdminStats({
    required this.totalRequests,
    required this.taxi,
    required this.depannage,
    required this.pending,
    required this.accepted,
    required this.inProgress,
    required this.completed,
    required this.refused,
    required this.cancelled,
    required this.totalUsers,
    required this.activeUsers,
    required this.totalDrivers,
    required this.availableDrivers,
    required this.openSupportTickets,
    required this.totalRevenue,
  });

  final int totalRequests;
  final int taxi;
  final int depannage;
  final int pending;
  final int accepted;
  final int inProgress;
  final int completed;
  final int refused;
  final int cancelled;
  final int totalUsers;
  final int activeUsers;
  final int totalDrivers;
  final int availableDrivers;
  final int openSupportTickets;
  final int totalRevenue;

  factory AdminStats.fromRequests(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    int totalUsers = 0,
    int activeUsers = 0,
    int totalDrivers = 0,
    int availableDrivers = 0,
    int openSupportTickets = 0,
    int totalRevenue = 0,
  }) {
    int taxi = 0;
    int depannage = 0;
    int pending = 0;
    int accepted = 0;
    int inProgress = 0;
    int completed = 0;
    int refused = 0;
    int cancelled = 0;

    for (final doc in docs) {
      final data = doc.data();

      switch (data['type']) {
        case RequestType.taxi:
          taxi++;
          break;
        case RequestType.depannage:
          depannage++;
          break;
      }

      switch (data['status']) {
        case RequestStatus.pending:
          pending++;
          break;
        case RequestStatus.accepted:
          accepted++;
          break;
        case RequestStatus.inProgress:
          inProgress++;
          break;
        case RequestStatus.completed:
          completed++;
          break;
        case RequestStatus.refused:
          refused++;
          break;
        case RequestStatus.cancelled:
          cancelled++;
          break;
      }
    }

    return AdminStats(
      totalRequests: docs.length,
      taxi: taxi,
      depannage: depannage,
      pending: pending,
      accepted: accepted,
      inProgress: inProgress,
      completed: completed,
      refused: refused,
      cancelled: cancelled,
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      totalDrivers: totalDrivers,
      availableDrivers: availableDrivers,
      openSupportTickets: openSupportTickets,
      totalRevenue: totalRevenue,
    );
  }
}

class DriverDraft {
  const DriverDraft({
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.plateNumber,
    this.rating = 4.8,
    this.active = true,
    this.available = true,
  });

  final String name;
  final String phone;
  final String vehicle;
  final String plateNumber;
  final double rating;
  final bool active;
  final bool available;

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name.trim(),
      'phone': phone.trim(),
      'vehicle': vehicle.trim(),
      'vehicleType': vehicle.trim(),
      'plateNumber': plateNumber.trim().toUpperCase(),
      'rating': rating,
      'active': active,
      'available': available,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class AdminService {
  AdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int defaultPageSize = 30;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _supportTickets =>
      _firestore.collection('supportTickets');

  CollectionReference<Map<String, dynamic>> get _payments =>
      _firestore.collection('payments');

  Query<Map<String, dynamic>> _requestsQuery() {
    return _requests.orderBy('createdAt', descending: true);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  watchRecentRequests({int limit = defaultPageSize}) {
    return _requestsQuery()
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchDrivers() {
    return _drivers.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs;
    });
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchUsers() {
    return _users.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs;
    });
  }

  Future<AdminStats> fetchStats() async {
    final counts = await Future.wait<int>([
      _count(_requests),
      _count(_requests.where('type', isEqualTo: RequestType.taxi)),
      _count(_requests.where('type', isEqualTo: RequestType.depannage)),
      _count(_requests.where('status', isEqualTo: RequestStatus.pending)),
      _count(_requests.where('status', isEqualTo: RequestStatus.accepted)),
      _count(_requests.where('status', isEqualTo: RequestStatus.inProgress)),
      _count(_requests.where('status', isEqualTo: RequestStatus.completed)),
      _count(_requests.where('status', isEqualTo: RequestStatus.refused)),
      _count(_requests.where('status', isEqualTo: RequestStatus.cancelled)),
      _count(_users),
      _count(_users.where('status', isEqualTo: UserStatus.active)),
      _count(_drivers),
      _count(_drivers.where('available', isEqualTo: true)),
      _count(_supportTickets.where('status', isEqualTo: 'open')),
    ]);

    final paidPayments = await _payments
        .where('status', isEqualTo: 'paid')
        .limit(200)
        .get();
    final totalRevenue = paidPayments.docs.fold<int>(0, (sum, doc) {
      final amount = doc.data()['amount'];
      if (amount is int) return sum + amount;
      if (amount is num) return sum + amount.round();
      return sum;
    });

    return AdminStats(
      totalRequests: counts[0],
      taxi: counts[1],
      depannage: counts[2],
      pending: counts[3],
      accepted: counts[4],
      inProgress: counts[5],
      completed: counts[6],
      refused: counts[7],
      cancelled: counts[8],
      totalUsers: counts[9],
      activeUsers: counts[10],
      totalDrivers: counts[11],
      availableDrivers: counts[12],
      openSupportTickets: counts[13],
      totalRevenue: totalRevenue,
    );
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchRequestsPage({
    int limit = defaultPageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    var query = _requestsQuery().limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.get();
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    if (!RequestStatus.all.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Invalid request status');
    }

    await _requests.doc(requestId).update({
      'status': status,
      'isActive': RequestStatus.activeStatuses.contains(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignDriver({
    required String requestId,
    required String driverId,
  }) async {
    final driver = await _drivers.doc(driverId).get();
    final data = driver.data();

    if (!driver.exists || data == null) {
      throw StateError('Chauffeur introuvable');
    }

    await _requests.doc(requestId).update({
      'driverId': driver.id,
      'driverName': data['name']?.toString() ?? '',
      'driverPhone': data['phone']?.toString() ?? '',
      'driverVehicle': data['vehicle']?.toString() ?? '',
      'driverPlate': data['plateNumber']?.toString() ?? '',
      'status': RequestStatus.accepted,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRequestNotes({
    required String requestId,
    required String notes,
  }) async {
    await _requests.doc(requestId).update({
      'adminNotes': notes.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRequest(String requestId) {
    return _requests.doc(requestId).delete();
  }

  Future<void> createDriver(DriverDraft driver) async {
    if (driver.name.trim().length < 2 ||
        driver.phone.trim().length < 6 ||
        driver.vehicle.trim().length < 2 ||
        driver.plateNumber.trim().length < 3) {
      throw ArgumentError('Informations chauffeur incompletes');
    }

    final doc = _drivers.doc();
    await doc.set({...driver.toCreateMap(), 'uid': doc.id});
  }

  Future<void> updateDriver({
    required String driverId,
    required DriverDraft driver,
  }) async {
    if (driver.name.trim().length < 2 ||
        driver.phone.trim().length < 6 ||
        driver.vehicle.trim().length < 2 ||
        driver.plateNumber.trim().length < 3) {
      throw ArgumentError('Informations chauffeur incompletes');
    }

    await _drivers.doc(driverId).update({
      'name': driver.name.trim(),
      'phone': driver.phone.trim(),
      'vehicle': driver.vehicle.trim(),
      'vehicleType': driver.vehicle.trim(),
      'plateNumber': driver.plateNumber.trim().toUpperCase(),
      'rating': driver.rating,
      'active': driver.active,
      'available': driver.available,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setDriverAvailability({
    required String driverId,
    required bool available,
  }) {
    return _drivers.doc(driverId).update({
      'available': available,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDriver(String driverId) {
    return _drivers.doc(driverId).delete();
  }

  Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    if (status != UserStatus.active && status != UserStatus.suspended) {
      throw ArgumentError.value(status, 'status', 'Invalid user status');
    }

    await _users.doc(userId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
