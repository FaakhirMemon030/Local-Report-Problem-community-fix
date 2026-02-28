import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/problem_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    await _db.collection('problems').doc(problem.problemId).set(problem.toMap());
    
    // Increment user's total reports
    await _db.collection('users').doc(problem.reportedBy).update({
      'totalReports': FieldValue.increment(1),
    });
  }

  // Vote for a problem
  Future<void> voteProblem(String problemId, String userId) async {
    // This will be handled by Cloud Functions securely, 
    // but we can add a record to the 'votes' collection.
    // The Cloud Function will trigger on this creation.
    await _db.collection('votes').add({
      'problemId': problemId,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
