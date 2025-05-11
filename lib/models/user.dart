class User {
  final String id;
  final String name;
  final String email;
  final String? address;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? dateOfBirth;
  final bool? verified;
  final int? points;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.address,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.dateOfBirth,
    this.verified,
    this.points,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      address: json['address'],
      image: json['image'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      dateOfBirth: json['dateOfBirth'],
      verified: json['verified'],
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
} 