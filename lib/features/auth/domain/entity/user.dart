class User {
  final int id;
  final String email;
  final String fullname;
  final int? age;
  final String? phone;
  final bool enabled;
  final String token;

  User({
    required this.id,
    required this.email,
    required this.fullname,
    this.age,
    this.phone,
    required this.enabled,
    required this.token,
  });
}