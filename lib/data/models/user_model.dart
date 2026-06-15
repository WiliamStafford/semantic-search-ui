// class UserModel {
//   final int id;
//   final String email;
//   final String fullName;
//   final String? avatar;
//   final int? age;
//   final String? phone;
//   final bool enabled;
//   final DateTime createdAt;
//   final List<String> roles;
//
//   UserModel({
//     required this.id,
//     required this.email,
//     required this.fullName,
//     this.avatar,
//     this.age,
//     this.phone,
//     required this.enabled,
//     required this.createdAt,
//     required this.roles,
//   });
//
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'],
//       email: json['email'],
//       fullName: json['fullName'] ?? 'Chưa cập nhật',
//       avatar: json['avatar'],
//       age: json['age'],
//       phone: json['phone'] ?? 'Chưa có SĐT',
//       enabled: json['enabled'] ?? true,
//       createdAt: DateTime.parse(json['createdAt']),
//       roles: (json['roles'] as List?)
//           ?.map((role) => role['name'].toString())
//           .toList() ?? [],
//     );
//   }
// }
class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String? avatar;
  final int? age;
  final String? phone;
  final bool enabled;
  final DateTime createdAt;
  final List<String> roles;

  // Thêm 5 trường địa chỉ
  final String? province;
  final String? district;
  final String? ward;
  final String? street;
  final String? houseNumber;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatar,
    this.age,
    this.phone,
    required this.enabled,
    required this.createdAt,
    required this.roles,
    // Cập nhật constructor
    this.province,
    this.district,
    this.ward,
    this.street,
    this.houseNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'] ?? 'Chưa cập nhật',
      avatar: json['avatar'],
      age: json['age'],
      phone: json['phone'],
      enabled: json['enabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      roles: (json['roles'] as List?)
          ?.map((role) => role['name'].toString())
          .toList() ?? [],
      province: json['province'],
      district: json['district'],
      ward: json['ward'],
      street: json['street'],
      houseNumber: json['houseNumber'],
    );
  }
}