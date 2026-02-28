import 'package:flutter/material.dart';
import '../models/daily_log_model.dart';
import '../models/goal_model.dart';
import '../models/simulation_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../simulation_engine/simulation_algorithm.dart';

class SimulationProvider with ChangeNotifier {
  FirestoreService get _firestoreService => FirestoreService();
  List<GoalModel> _goals = [];
  List<DailyLogModel> _logs = [];
  List<FutureSimulationModel> _simulations = [];
  bool _isLoading = false;
  String? _currentUserId;

  List<GoalModel> get goals => _goals;
  List<DailyLogModel> get logs => _logs;
  List<FutureSimulationModel> get simulations => _simulations;
  bool get isLoading => _isLoading;

  void loadUserData(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    _isLoading = true;
    notifyListeners();

    _firestoreService.getGoals(userId).listen((newGoals) {
      _goals = newGoals;
      notifyListeners();
    });

    _firestoreService.getDailyLogs(userId).listen((newLogs) {
      _logs = newLogs;
      notifyListeners();
    });

    _firestoreService.getSimulations(userId).listen((newSims) {
      _simulations = newSims;
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  void clearUserData() {
    _currentUserId = null;
    _goals = [];
    _logs = [];
    _simulations = [];
    notifyListeners();
  }

  Future<void> runSimulation(UserModel user, String timelineType) async {
    _isLoading = true;
    notifyListeners();

    FutureSimulationModel simulation = SimulationAlgorithm.generateSimulation(
      user: user,
      logs: _logs,
      goals: _goals,
      timelineType: timelineType,
    );

    await _firestoreService.saveSimulation(simulation);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(DailyLogModel log) async {
    await _firestoreService.addDailyLog(log);
  }

  Future<void> addGoal(GoalModel goal) async {
    await _firestoreService.addGoal(goal);
  }
}
