class User {
  final String name;
  final String email;
  final String dateOfBirth;
  final String role;

  User({
    required this.name,
    required this.email,
    required this.dateOfBirth,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
    );
  }
}