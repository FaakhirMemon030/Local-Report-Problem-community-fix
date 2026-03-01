import 'package:cloud_firestore/cloud_firestore.dart';

enum ProblemStatus { pending, approved, inProgress, solved, rejected }

class ProblemModel {
  final String problemId;
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final String imageUrl;
  final String reportedBy;
  final int voteCount;
  final double priorityScore;
  final ProblemStatus status;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String city;
  final String district;

  ProblemModel({
    required this.problemId,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.imageUrl,
    required this.reportedBy,
    required this.voteCount,
    required this.priorityScore,
    required this.status,
    required this.createdAt,
    required this.lastUpdated,
    required this.city,
    required this.district,
  });

  factory ProblemModel.fromMap(Map<String, dynamic> data, String id) {
    try {
      return ProblemModel(
        problemId: id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        category: data['category'] ?? '',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
        address: data['address'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        reportedBy: data['reportedBy'] ?? '',
        voteCount: (data['voteCount'] as num?)?.toInt() ?? 0,
        priorityScore: (data['priorityScore'] as num?)?.toDouble() ?? 0.0,
        status: data['status'] != null 
            ? ProblemStatus.values.byName(data['status']) 
            : ProblemStatus.pending,
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate() 
            : DateTime.now(),
        lastUpdated: data['lastUpdated'] != null 
            ? (data['lastUpdated'] as Timestamp).toDate() 
            : DateTime.now(),
        city: data['city'] ?? '',
        district: data['district'] ?? '',
      );
    } catch (e) {
      print("LPRCF: Error parsing ProblemModel ($id): $e");
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'imageUrl': imageUrl,
      'reportedBy': reportedBy,
      'voteCount': voteCount,
      'priorityScore': priorityScore,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'city': city,
      'district': district,
    };
  }
}
