library realtime_sdk;

class ActiveTripView {
  const ActiveTripView({
    required this.tripId,
    required this.status,
  });

  final String tripId;
  final String status;
}
