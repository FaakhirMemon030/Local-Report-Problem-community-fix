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

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      userId: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      city: data['city'] ?? '',
      password: data['password'],
      reputationScore: data['reputationScore'] ?? 0,
      totalReports: data['totalReports'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isBanned: data['isBanned'] ?? false,
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
