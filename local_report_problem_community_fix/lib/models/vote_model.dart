import 'package:cloud_firestore/cloud_firestore.dart';

class VoteModel {
  final String voteId;
  final String problemId;
  final String userId;
  final DateTime createdAt;

  VoteModel({
    required this.voteId,
    required this.problemId,
    required this.userId,
    required this.createdAt,
  });

  factory VoteModel.fromMap(Map<String, dynamic> data, String id) {
    return VoteModel(
      voteId: id,
      problemId: data['problemId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'problemId': problemId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
