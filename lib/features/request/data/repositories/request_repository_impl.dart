import '../../../../models/request_model.dart';
import '../../domain/repositories/request_repository.dart';
import '../datasources/request_firebase_datasource.dart';

class RequestRepositoryImpl implements RequestRepository {
  RequestRepositoryImpl({RequestFirebaseDataSource? dataSource})
      : _dataSource = dataSource ?? RequestFirebaseDataSource();

  final RequestFirebaseDataSource _dataSource;

  @override
  Future<String> createClientRequest({
    required String type,
    String description = '',
    String pickupAddress = 'Niamey, Niger',
    String destinationAddress = '',
    int? price,
  }) {
    return _dataSource.createRequest(
      type: type,
      description: description,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      price: price,
    );
  }

  @override
  Stream<List<RequestModel>> watchUserRequests(String userId) {
    return _dataSource.watchUserRequests(userId);
  }

  @override
  Stream<RequestModel?> watchRequest(String requestId) {
    return _dataSource.watchRequest(requestId);
  }

  @override
  Future<void> cancelRequest(String requestId) {
    return _dataSource.cancelRequest(requestId);
  }
}
