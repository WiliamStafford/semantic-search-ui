class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final int? age;
  final String? avatar;
  final List<String> roles;
  final DateTime? createdAt;
  final bool enabled;

  final String? province;
  final String? district;
  final String? ward;
  final String? street;
  final String? houseNumber;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.age,
    this.avatar,
    required this.roles,
    required this.enabled,
    this.createdAt,
    this.province,
    this.district,
    this.ward,
    this.street,
    this.houseNumber,
  });

  // factory UserModel.fromJson(Map<String, dynamic> json) {
  //   return UserModel(
  //     id: json['id'] as int? ?? 0,
  //     email: json['email'] as String? ?? '',
  //     fullName: json['fullName'] as String? ?? '',
  //     phone: json['phone'] as String?,
  //     age: json['age'] as int?,
  //     avatar: json['avatar'] as String?,
  //     roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
  //     createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
  //
  //     province: json['province']?.toString() ?? '',
  //     district: json['district']?.toString() ?? '',
  //     ward: json['ward']?.toString() ?? '',
  //     street: json['street']?.toString() ?? '',
  //     houseNumber: json['houseNumber']?.toString() ?? '',
  //   );
  // }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt(),
      enabled: json['enabled'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,

      province: json['province']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      houseNumber: json['houseNumber']?.toString() ?? '',
    );
  }
}