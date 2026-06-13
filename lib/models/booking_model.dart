class BookingModel {
  final String id;
  final String departure;
  final String destination;
  final String status;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.departure,
    required this.destination,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return BookingModel(
      id: id,
      departure: map['departure'] ?? '',
      destination: map['destination'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.now(),
    );
  }
}