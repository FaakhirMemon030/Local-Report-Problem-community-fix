import 'package:flutter/material.dart';
import '../models/problem_model.dart';
import '../services/firestore_service.dart';

class ProblemProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<ProblemModel> _problems = [];
  bool _isLoading = false;

  List<ProblemModel> get problems => _problems;
  bool get isLoading => _isLoading;

  void fetchProblems({String? category, String? city, String? status, String? sortBy}) {
    _isLoading = true;
    _firestoreService.getProblems(
      category: category,
      city: city,
      status: status,
      sortBy: sortBy,
    ).listen((updatedProblems) {
      _problems = updatedProblems;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> reportProblem(ProblemModel problem) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.reportProblem(problem);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> voteProblem(String problemId, String userId) async {
    await _firestoreService.voteProblem(problemId, userId);
  }
}
