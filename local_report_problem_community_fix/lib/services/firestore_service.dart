import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/problem_model.dart';
import '../models/user_model.dart';
import '../models/worker_model.dart';
import '../models/assignment_model.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Stream of problems with filtering
  Stream<List<ProblemModel>> getProblems({
    String? category,
    String? city,
    String? status,
    String? sortBy,
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
        .map((doc) => ProblemModel.fromMap(doc.data() as Map<String, dynamic>?, doc.id))
        .toList());
  }

  Future<void> reportProblem(ProblemModel problem) async {
    try {
      print("LPRCF: Starting reportProblem for ID: ${problem.problemId}");
      await _db.collection('problems').doc(problem.problemId).set(problem.toMap());
      print("LPRCF: 'problems' document set successfully.");
      await _db.collection('users').doc(problem.reportedBy).set({
        'totalReports': FieldValue.increment(1),
      }, SetOptions(merge: true));
      print("LPRCF: User report count incremented successfully.");
    } catch (e) {
      print("LPRCF: Firestore Error in reportProblem: $e");
      rethrow;
    }
  }

  Future<void> voteProblem(String problemId, String userId) async {
    try {
      // Check if user already voted
      final existing = await _db
          .collection('votes')
          .where('problemId', isEqualTo: problemId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('already_voted');
      }

      await _db.collection('votes').add({
        'problemId': problemId,
        'userId': userId,
        'createdAt': DateTime.now(),
      });
      await _db.collection('problems').doc(problemId).update({
        'voteCount': FieldValue.increment(1),
        'priorityScore': FieldValue.increment(1.0),
        'lastUpdated': DateTime.now(),
      });
    } catch (e) {
      print("LPRCF: Firestore Error in voteProblem: $e");
      rethrow;
    }
  }

  Future<bool> hasUserVoted(String problemId, String userId) async {
    try {
      final snap = await _db
          .collection('votes')
          .where('problemId', isEqualTo: problemId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }


  Future<void> updateProblemStatus(String problemId, ProblemStatus status, String adminId) async {
    await _db.collection('problems').doc(problemId).update({
      'status': status.name,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    await _db.collection('admin_logs').add({
      'problemId': problemId,
      'actionType': 'status_change_${status.name}',
      'actionBy': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProblem(String problemId, String adminId) async {
    await _db.collection('problems').doc(problemId).delete();
    await _db.collection('admin_logs').add({
      'problemId': problemId,
      'actionType': 'delete_problem',
      'actionBy': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>?, doc.id))
        .toList());
  }

  Future<void> updateUserBanStatus(String userId, bool isBanned) async {
    await _db.collection('users').doc(userId).update({'isBanned': isBanned});
  }

  Future<void> deleteUser(String userId, String adminId) async {
    await _db.collection('users').doc(userId).delete();
    await _db.collection('admin_logs').add({
      'targetUserId': userId,
      'actionType': 'delete_user_kick',
      'actionBy': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─── WORKER MANAGEMENT ────────────────────────────────────

  Stream<List<WorkerModel>> getAllWorkers() {
    return _db.collection('workers').orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((doc) => WorkerModel.fromMap(doc.data() as Map<String, dynamic>?, doc.id))
              .toList(),
        );
  }

  Future<void> updateWorkerStatus(String workerId, WorkerStatus status, String adminId) async {
    await _db.collection('workers').doc(workerId).update({'status': status.name});
    await _db.collection('admin_logs').add({
      'targetWorkerId': workerId,
      'actionType': 'worker_status_${status.name}',
      'actionBy': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWorkerBanStatus(String workerId, bool isBanned) async {
    await _db.collection('workers').doc(workerId).update({'isBanned': isBanned});
  }

  Future<void> deleteWorker(String workerId, String adminId) async {
    await _db.collection('workers').doc(workerId).delete();
    await _db.collection('admin_logs').add({
      'targetWorkerId': workerId,
      'actionType': 'delete_worker_kick',
      'actionBy': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─── JOB ASSIGNMENTS ──────────────────────────────────────

  Future<void> assignProblemToWorker(AssignmentModel assignment) async {
    await _db.collection('assignments').doc(assignment.assignmentId).set(assignment.toMap());
    await _db.collection('admin_logs').add({
      'problemId': assignment.problemId,
      'workerId': assignment.workerId,
      'actionType': 'assign_problem',
      'actionBy': assignment.assignedBy,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AssignmentModel>> getAssignmentsForWorker(String workerId, {String? workerCategory}) {
    return _db.collection('assignments')
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => AssignmentModel.fromMap(doc.data() as Map<String, dynamic>?, doc.id))
              .toList();
          // Filter by category if provided
          final filtered = workerCategory != null
              ? list.where((a) => _isMatchingCategory(workerCategory, a.problemCategory)).toList()
              : list;
          // Sort locally to avoid requiring a composite Firestore index
          filtered.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
          return filtered;
        });
  }

  bool _isMatchingCategory(String wCatRaw, String pCatRaw) {
    final wCat = wCatRaw.toLowerCase();
    final pCat = pCatRaw.toLowerCase();
    if (pCat == 'electricity' && wCat == 'electrician') return true;
    if (pCat == 'water' && (wCat == 'plumber' || wCat == 'water')) return true;
    if (pCat == wCat) return true;
    return false;
  }

  Stream<List<AssignmentModel>> getAllAssignments() {
    return _db
        .collection('assignments')
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AssignmentModel.fromMap(doc.data() as Map<String, dynamic>?, doc.id))
            .toList());
  }

  Future<void> markAssignmentDone(String assignmentId, String notes, {String completionImageUrl = ''}) async {
    await _db.collection('assignments').doc(assignmentId).update({
      'status': AssignmentStatus.done.name,
      'workerNotes': notes,
      'completionImageUrl': completionImageUrl,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProblemImage(String problemId, String newImageUrl) async {
    await _db.collection('problems').doc(problemId).update({
      'imageUrl': newImageUrl,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementWorkerJobsDone(String workerId) async {
    await _db
        .collection('workers')
        .doc(workerId)
        .update({'jobsDone': FieldValue.increment(1)});
  }
}
