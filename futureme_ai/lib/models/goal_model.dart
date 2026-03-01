class GoalModel {
  final String goalId;
  final String userId;
  final String title;
  final String category; // health, career, finance
  final double targetValue;
  final DateTime deadline;
  final double progress;

  GoalModel({
    required this.goalId,
    required this.userId,
    required this.title,
    required this.category,
    required this.targetValue,
    required this.deadline,
    required this.progress,
  });

  Map<String, dynamic> toMap() {
    return {
      'goalId': goalId,
      'userId': userId,
      'title': title,
      'category': category,
      'targetValue': targetValue,
      'deadline': deadline.toIso8601String(),
      'progress': progress,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      goalId: map['goalId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'career',
      targetValue: (map['targetValue'] ?? 0).toDouble(),
      deadline: DateTime.parse(map['deadline'] ?? DateTime.now().toIso8601String()),
      progress: (map['progress'] ?? 0).toDouble(),
    );
  }
}
