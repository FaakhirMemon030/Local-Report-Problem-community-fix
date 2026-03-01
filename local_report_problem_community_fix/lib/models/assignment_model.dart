import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { assigned, inProgress, done }

class AssignmentModel {
  final String assignmentId;
  final String problemId;
  final String problemTitle;
  final String problemCategory;
  final String problemCity;
  final String problemAddress;
  final String problemImageUrl;
  final String workerId;
  final String workerName;
  final String assignedBy; // admin userId
  final AssignmentStatus status;
  final String workerNotes;
  final DateTime assignedAt;
  final DateTime? completedAt;

  AssignmentModel({
    required this.assignmentId,
    required this.problemId,
    required this.problemTitle,
    required this.problemCategory,
    required this.problemCity,
    required this.problemAddress,
    required this.problemImageUrl,
    required this.workerId,
    required this.workerName,
    required this.assignedBy,
    this.status = AssignmentStatus.assigned,
    this.workerNotes = '',
    required this.assignedAt,
    this.completedAt,
  });

  factory AssignmentModel.fromMap(Map<String, dynamic>? data, String id) {
    final map = data ?? {};
    AssignmentStatus st = AssignmentStatus.assigned;
    try { st = AssignmentStatus.values.byName(map['status'] ?? 'assigned'); } catch (_) {}

    return AssignmentModel(
      assignmentId: id,
      problemId: map['problemId'] ?? '',
      problemTitle: map['problemTitle'] ?? '',
      problemCategory: map['problemCategory'] ?? '',
      problemCity: map['problemCity'] ?? '',
      problemAddress: map['problemAddress'] ?? '',
      problemImageUrl: map['problemImageUrl'] ?? '',
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      status: st,
      workerNotes: map['workerNotes'] ?? '',
      assignedAt: map['assignedAt'] != null && map['assignedAt'] is Timestamp
          ? (map['assignedAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: map['completedAt'] != null && map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'problemId': problemId,
    'problemTitle': problemTitle,
    'problemCategory': problemCategory,
    'problemCity': problemCity,
    'problemAddress': problemAddress,
    'problemImageUrl': problemImageUrl,
    'workerId': workerId,
    'workerName': workerName,
    'assignedBy': assignedBy,
    'status': status.name,
    'workerNotes': workerNotes,
    'assignedAt': Timestamp.fromDate(assignedAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
  };
}
