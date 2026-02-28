import '../models/daily_log_model.dart';
import '../models/goal_model.dart';
import '../models/simulation_model.dart';
import '../models/user_model.dart';

class SimulationAlgorithm {
  static FutureSimulationModel generateSimulation({
    required UserModel user,
    required List<DailyLogModel> logs,
    required List<GoalModel> goals,
    required String timelineType, // growth, lazy, balanced
  }) {
    // 1. Calculate Average Daily Stats
    double avgCodingHours = 0;
    double avgWorkoutMinutes = 0;
    double avgProductivity = 0;
    double avgWastedTime = 0;

    if (logs.isNotEmpty) {
      avgCodingHours = logs.map((l) => l.codingHours).reduce((a, b) => a + b) / logs.length;
      avgWorkoutMinutes = logs.map((l) => l.workoutMinutes).reduce((a, b) => a + b) / logs.length;
      avgProductivity = logs.map((l) => l.productivityScore).reduce((a, b) => a + b) / logs.length;
      avgWastedTime = logs.map((l) => l.wastedTime).reduce((a, b) => a + b) / logs.length;
    }

    // 2. Multipliers based on timelineType
    double growthMultiplier = 1.0;
    if (timelineType == 'growth') {
      growthMultiplier = 1.5;
    } else if (timelineType == 'lazy') {
      growthMultiplier = 0.5;
    }

    // 3. Career Projection
    double careerProgress = (avgCodingHours * 0.4 + avgProductivity * 0.6) * growthMultiplier;
    String careerPrediction = _generateCareerText(careerProgress, user.profession);

    // 4. Health Projection
    double healthProgress = (avgWorkoutMinutes / 60 * 0.7 - avgWastedTime / 60 * 0.3) * growthMultiplier;
    String healthPrediction = _generateHealthText(healthProgress, user.currentHealthScore);

    // 5. Wealth Projection
    double wealthProgress = (user.baseSalary * (1 + (careerProgress / 100))) * growthMultiplier;
    String wealthPrediction = _generateWealthText(wealthProgress);

    // 6. Risk Warnings
    List<String> warnings = [];
    if (avgWastedTime > (avgCodingHours + avgWorkoutMinutes / 60)) {
      warnings.add('Your wasted time exceeds your productive hours. High risk of stagnancy.');
    }
    if (avgWorkoutMinutes < 20) {
      warnings.add('Low physical activity detected. Long-term health risks ahead.');
    }

    return FutureSimulationModel(
      simulationId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.userId,
      projectionYear: 5,
      careerPrediction: careerPrediction,
      healthPrediction: healthPrediction,
      wealthPrediction: wealthPrediction,
      riskWarnings: warnings,
      timelineType: timelineType,
    );
  }

  static String _generateCareerText(double progress, String profession) {
    if (progress > 80) return 'Exceptional growth! You are on track to become a lead $profession and a recognized expert in your field.';
    if (progress > 50) return 'Steady advancement. You will likely reach senior $profession level with significant responsibilities.';
    return 'Moderate growth. You will remain stable in your $profession role but may miss out on high-tier opportunities.';
  }

  static String _generateHealthText(double progress, double currentScore) {
    if (progress > 0.8) return 'Peak physical condition. Your energy levels and mental clarity will be at an all-time high.';
    if (progress > 0.4) return 'Good health maintenance. You will stay fit and avoid most lifestyle-related ailments.';
    return 'Warning: Declining health trajectory. Consider increasing physical activity to avoid burnout or fatigue.';
  }

  static String _generateWealthText(double estimatedValue) {
    return 'Estimated annual wealth potential: \$${estimatedValue.toStringAsFixed(2)}. Consistent logs show a strong financial upwards trend.';
  }
}
