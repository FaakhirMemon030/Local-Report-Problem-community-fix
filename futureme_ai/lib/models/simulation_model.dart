class FutureSimulationModel {
  final String simulationId;
  final String userId;
  final int projectionYear;
  final String careerPrediction;
  final String healthPrediction;
  final String wealthPrediction;
  final List<String> riskWarnings;
  final String timelineType; // growth / lazy / balanced

  FutureSimulationModel({
    required this.simulationId,
    required this.userId,
    required this.projectionYear,
    required this.careerPrediction,
    required this.healthPrediction,
    required this.wealthPrediction,
    required this.riskWarnings,
    required this.timelineType,
  });

  Map<String, dynamic> toMap() {
    return {
      'simulationId': simulationId,
      'userId': userId,
      'projectionYear': projectionYear,
      'careerPrediction': careerPrediction,
      'healthPrediction': healthPrediction,
      'wealthPrediction': wealthPrediction,
      'riskWarnings': riskWarnings,
      'timelineType': timelineType,
    };
  }

  factory FutureSimulationModel.fromMap(Map<String, dynamic> map) {
    return FutureSimulationModel(
      simulationId: map['simulationId'] ?? '',
      userId: map['userId'] ?? '',
      projectionYear: map['projectionYear'] ?? 0,
      careerPrediction: map['careerPrediction'] ?? '',
      healthPrediction: map['healthPrediction'] ?? '',
      wealthPrediction: map['wealthPrediction'] ?? '',
      riskWarnings: List<String>.from(map['riskWarnings'] ?? []),
      timelineType: map['timelineType'] ?? 'balanced',
    );
  }
}
