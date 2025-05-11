class Admin {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool verified;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.verified,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      verified: json['verified'] ?? false,
    );
  }
}