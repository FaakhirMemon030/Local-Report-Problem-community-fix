import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/problem_model.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Stream of problems with filtering
  Stream<List<ProblemModel>> getProblems({
    String? category,
    String? city,
    String? status,
    String? sortBy, // 'priorityScore', 'createdAt', 'voteCount'
  }) {
    Query query = _db.collection('problems');

    if (category != null && category != 'other') {
      query = query.where('category', isEqualTo: category);
    }
    if (city != null) {
      query = query.where('city', isEqualTo: city);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (sortBy == 'priorityScore') {
      query = query.orderBy('priorityScore', descending: true);
    } else if (sortBy == 'voteCount') {
      query = query.orderBy('voteCount', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ProblemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Report a new problem
  Future<void> reportProblem(ProblemModel problem) async {
    try {
      print("LPRCF: Starting reportProblem for ID: ${problem.problemId}");
      
      final problemData = problem.toMap();
      print("LPRCF: Model converted to Map successfully.");

      await _db.collection('problems').doc(problem.problemId).set(problemData);
      print("LPRCF: 'problems' document set successfully.");
      
      // Increment user's total reports (Safer implementation for web)
      print("LPRCF: Updating user: ${problem.reportedBy}");
      await _db.collection('users').doc(problem.reportedBy).set({
        'totalReports': FieldValue.increment(1),
      }, SetOptions(merge: true));
      
      print("LPRCF: User report count incremented successfully.");
    } catch (e) {
      print("LPRCF: Firestore Error in reportProblem: $e");
      rethrow;
    }
  }

  // Vote for a problem
  Future<void> voteProblem(String problemId, String userId) async {
    try {
      print("LPRCF: Starting voteProblem for Problem: $problemId by User: $userId");
      
      // 1. Add record to 'votes' collection
      await _db.collection('votes').add({
        'problemId': problemId,
        'userId': userId,
        'createdAt': DateTime.now(),
      });

      // 2. Increment voteCount and update priorityScore on the problem document
      // We do this directly since Cloud Functions might not be set up/running.
      print("LPRCF: Incrementing voteCount in problems collection...");
      await _db.collection('problems').doc(problemId).update({
        'voteCount': FieldValue.increment(1),
        'priorityScore': FieldValue.increment(1.0), // Simplified priority update
        'lastUpdated': DateTime.now(),
      });

      print("LPRCF: Vote and count update successful.");
    } catch (e) {
      print("LPRCF: Firestore Error in voteProblem: $e");
      rethrow;
    }
  }

  // Admin: Update problem status
  Future<void> updateProblemStatus(String problemId, ProblemStatus status, String adminId) async {
    await _db.collection('problems').doc(problemId).update({
      'status': status.name,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Log the action
    await _db.collection('admin_logs').add({
      'problemId': problemId,
      'actionType': 'status_change_${status.name}',
      'actionBy': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
