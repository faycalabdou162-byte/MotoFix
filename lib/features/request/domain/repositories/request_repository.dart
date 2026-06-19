import '../../../../models/request_model.dart';

/// Contract for client service requests (taxi / depannage).
abstract class RequestRepository {
  Future<String> createClientRequest({
    required String type,
    String description,
    String pickupAddress,
    String destinationAddress,
    int? price,
  });

  Stream<List<RequestModel>> watchUserRequests(String userId);

  Stream<RequestModel?> watchRequest(String requestId);

  Future<void> cancelRequest(String requestId);

  static int defaultPriceFor(String type) =>
      type == RequestType.taxi ? 2000 : 3000;
}
