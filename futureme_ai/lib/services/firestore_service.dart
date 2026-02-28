import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/goal_model.dart';
import '../models/daily_log_model.dart';
import '../models/simulation_model.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Goals
  Future<void> addGoal(GoalModel goal) async {
    await _db.collection('goals').doc(goal.goalId).set(goal.toMap());
  }

  Stream<List<GoalModel>> getGoals(String userId) {
    return _db
        .collection('goals')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalModel.fromMap(doc.data()))
            .toList());
  }

  // Daily Logs
  Future<void> addDailyLog(DailyLogModel log) async {
    await _db.collection('daily_logs').doc(log.logId).set(log.toMap());
  }

  Stream<List<DailyLogModel>> getDailyLogs(String userId) {
    return _db
        .collection('daily_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyLogModel.fromMap(doc.data()))
            .toList());
  }

  // Simulations
  Future<void> saveSimulation(FutureSimulationModel simulation) async {
    await _db.collection('future_simulations').doc(simulation.simulationId).set(simulation.toMap());
  }

  Stream<List<FutureSimulationModel>> getSimulations(String userId) {
    return _db
        .collection('future_simulations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FutureSimulationModel.fromMap(doc.data()))
            .toList());
  }

  // Admin: Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }
}
