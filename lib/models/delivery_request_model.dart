class DeliveryRequest {
  final String? id;
  final String userId;
  final String serviceType; // 'Demenagement', 'Transport', 'Coursier'
  final String city; // Nouvelle ville
  final String pickupAddress;
  final String destinationAddress;
  final String description;
  final String contactPhone;
  final String status; // 'pending', 'accepted', 'completed'
  final DateTime createdAt;

  DeliveryRequest({
    this.id,
    required this.userId,
    required this.serviceType,
    required this.city,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.description,
    required this.contactPhone,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'service_type': serviceType,
      'city': city,
      'pickup_address': pickupAddress,
      'destination_address': destinationAddress,
      'description': description,
      'contact_phone': contactPhone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DeliveryRequest.fromMap(Map<String, dynamic> map, String id) {
    return DeliveryRequest(
      id: id,
      userId: map['user_id']?.toString() ?? '',
      serviceType: map['service_type']?.toString() ?? '',
      city: map['city']?.toString() ?? 'Ouagadougou',
      pickupAddress: map['pickup_address']?.toString() ?? '',
      destinationAddress: map['destination_address']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      contactPhone: map['contact_phone']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : DateTime.now(),
    );
  }
}
