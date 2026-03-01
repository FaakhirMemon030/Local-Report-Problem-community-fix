import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLogModel {
  final String actionId;
  final String problemId;
  final String actionType;
  final String actionBy;
  final DateTime timestamp;

  AdminLogModel({
    required this.actionId,
    required this.problemId,
    required this.actionType,
    required this.actionBy,
    required this.timestamp,
  });

  factory AdminLogModel.fromMap(Map<String, dynamic> data, String id) {
    return AdminLogModel(
      actionId: id,
      problemId: data['problemId'] ?? '',
      actionType: data['actionType'] ?? '',
      actionBy: data['actionBy'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'problemId': problemId,
      'actionType': actionType,
      'actionBy': actionBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
