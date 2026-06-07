class ReservationModel {
  final String? id;

  // Infos véhicule
  final String vehicleId;
  final String vehicleModel;
  final String vehicleCompanyName;
  final String ownerId;

  // Infos utilisateur
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhone;

  // Infos location
  final int numberOfDays;
  final bool withDriver;
  final double totalPrice;

  // Documents (URLs)
  final String cnibImage;
  final String cnibBackImage;
  final String licenseImage;

  // Statut
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  ReservationModel({
    this.id,
    required this.vehicleId,
    required this.vehicleModel,
    required this.vehicleCompanyName,
    required this.ownerId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.numberOfDays,
    required this.withDriver,
    required this.totalPrice,
    required this.cnibImage,
    required this.cnibBackImage,
    required this.licenseImage,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicle_id': vehicleId,
      'vehicle_model': vehicleModel,
      'vehicle_company_name': vehicleCompanyName,
      'owner_id': ownerId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_phone': userPhone,
      'number_of_days': numberOfDays,
      'with_driver': withDriver,
      'total_price': totalPrice,
      'cnib_image': cnibImage,
      'cnib_back_image': cnibBackImage,
      'license_image': licenseImage,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReservationModel.fromMap(Map<String, dynamic> map, String id) {
    return ReservationModel(
      id: id,
      vehicleId: (map['vehicle_id'] ?? map['vehicle'] ?? map['vehicleId'] ?? '').toString(),
      vehicleModel: map['vehicle_model'] ?? map['vehicleModel'] ?? '',
      vehicleCompanyName: map['vehicle_company_name'] ?? map['vehicleCompanyName'] ?? '',
      ownerId: (map['owner_id'] ?? map['owner'] ?? map['ownerId'] ?? '').toString(),
      userId: (map['user_id'] ?? map['user'] ?? map['userId'] ?? '').toString(),
      userName: map['user_name'] ?? map['userName'] ?? '',
      userEmail: map['user_email'] ?? map['userEmail'] ?? '',
      userPhone: map['user_phone'] ?? map['userPhone'],
      numberOfDays: map['number_of_days'] ?? map['numberOfDays'] ?? 1,
      withDriver: map['with_driver'] ?? map['withDriver'] ?? false,
      totalPrice: double.tryParse((map['total_price'] ?? map['totalPrice'] ?? '0.0').toString()) ?? 0.0,
      cnibImage: map['cnib_image'] ?? map['cnibImage'] ?? '',
      cnibBackImage: map['cnib_back_image'] ?? map['cnibBackImage'] ?? '',
      licenseImage: map['license_image'] ?? map['licenseImage'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now()),
    );
  }

  ReservationModel copyWith({String? status}) {
    return ReservationModel(
      id: id,
      vehicleId: vehicleId,
      vehicleModel: vehicleModel,
      vehicleCompanyName: vehicleCompanyName,
      ownerId: ownerId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      numberOfDays: numberOfDays,
      withDriver: withDriver,
      totalPrice: totalPrice,
      cnibImage: cnibImage,
      cnibBackImage: cnibBackImage,
      licenseImage: licenseImage,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
