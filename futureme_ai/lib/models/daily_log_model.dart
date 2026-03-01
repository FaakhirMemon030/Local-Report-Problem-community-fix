class DailyLogModel {
  final String logId;
  final String userId;
  final DateTime date;
  final double codingHours;
  final double workoutMinutes;
  final double learningTime;
  final double wastedTime;
  final String mood;
  final double productivityScore;

  DailyLogModel({
    required this.logId,
    required this.userId,
    required this.date,
    required this.codingHours,
    required this.workoutMinutes,
    required this.learningTime,
    required this.wastedTime,
    required this.mood,
    required this.productivityScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'userId': userId,
      'date': date.toIso8601String(),
      'codingHours': codingHours,
      'workoutMinutes': workoutMinutes,
      'learningTime': learningTime,
      'wastedTime': wastedTime,
      'mood': mood,
      'productivityScore': productivityScore,
    };
  }

  factory DailyLogModel.fromMap(Map<String, dynamic> map) {
    return DailyLogModel(
      logId: map['logId'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      codingHours: (map['codingHours'] ?? 0).toDouble(),
      workoutMinutes: (map['workoutMinutes'] ?? 0).toDouble(),
      learningTime: (map['learningTime'] ?? 0).toDouble(),
      wastedTime: (map['wastedTime'] ?? 0).toDouble(),
      mood: map['mood'] ?? 'neutral',
      productivityScore: (map['productivityScore'] ?? 0).toDouble(),
    );
  }
}
