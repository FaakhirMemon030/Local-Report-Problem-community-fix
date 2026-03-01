import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../models/assignment_model.dart';
import '../services/worker_auth_service.dart';
import '../services/firestore_service.dart';

class WorkerProvider with ChangeNotifier {
  final WorkerAuthService _authService = WorkerAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  WorkerModel? _workerModel;
  bool _isLoading = false;

  WorkerModel? get workerModel => _workerModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _workerModel != null;
  String? get workerId => _workerModel?.workerId;

  Stream<List<AssignmentModel>> get myAssignments {
    if (_workerModel == null) return const Stream.empty();
    return _firestoreService.getAssignmentsForWorker(_workerModel!.workerId);
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _workerModel = await _authService.signInWorker(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String cnic,
    required WorkerCategory category,
    required String city,
    required String address,
    String cnicPicUrl = '',
    String electricityBillUrl = '',
    String gasBillUrl = '',
    String profilePicUrl = '',
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _workerModel = await _authService.signUpWorker(
        email: email,
        password: password,
        name: name,
        phone: phone,
        cnic: cnic,
        category: category,
        city: city,
        address: address,
        cnicPicUrl: cnicPicUrl,
        electricityBillUrl: electricityBillUrl,
        gasBillUrl: gasBillUrl,
        profilePicUrl: profilePicUrl,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _workerModel = null;
    notifyListeners();
  }

  Future<void> markAssignmentDone(String assignmentId, String notes) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.markAssignmentDone(assignmentId, notes);
      if (_workerModel != null) {
        await _firestoreService.incrementWorkerJobsDone(_workerModel!.workerId);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
