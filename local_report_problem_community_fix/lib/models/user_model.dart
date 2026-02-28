import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String city;
  final int reputationScore;
  final int totalReports;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.city,
    required this.reputationScore,
    required this.totalReports,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      userId: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      city: data['city'] ?? '',
      reputationScore: data['reputationScore'] ?? 0,
      totalReports: data['totalReports'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'city': city,
      'reputationScore': reputationScore,
      'totalReports': totalReports,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
