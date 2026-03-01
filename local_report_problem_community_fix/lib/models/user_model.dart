import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String city;
  final String? password; // Storing password as requested
  final int reputationScore;
  final int totalReports;
  final DateTime createdAt;
  final bool isBanned;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.city,
    this.password,
    required this.reputationScore,
    required this.totalReports,
    required this.createdAt,
    this.isBanned = false,
  });

  factory UserModel.fromMap(Map<String, dynamic>? data, String id) {
    final Map<String, dynamic> map = data ?? {};
    return UserModel(
      userId: id,
      name: map['name'] ?? 'User',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      city: map['city'] ?? '',
      password: map['password'],
      reputationScore: map['reputationScore'] ?? 0,
      totalReports: map['totalReports'] ?? 0,
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isBanned: map['isBanned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'city': city,
      'password': password,
      'reputationScore': reputationScore,
      'totalReports': totalReports,
      'createdAt': Timestamp.fromDate(createdAt),
      'isBanned': isBanned,
    };
  }

  UserModel copyWith({
    String? name,
    String? city,
    String? password,
    int? reputationScore,
    int? totalReports,
    bool? isBanned,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      email: email,
      role: role,
      city: city ?? this.city,
      password: password ?? this.password,
      reputationScore: reputationScore ?? this.reputationScore,
      totalReports: totalReports ?? this.totalReports,
      createdAt: createdAt,
      isBanned: isBanned ?? this.isBanned,
    );
  }
}
