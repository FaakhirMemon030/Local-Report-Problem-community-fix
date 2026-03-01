import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';

class WorkerAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<WorkerModel?> getWorkerModel(String uid) async {
    try {
      final doc = await _db.collection('workers').doc(uid).get();
      if (doc.exists) {
        return WorkerModel.fromMap(doc.data(), doc.id);
      }
    } catch (e) {
      print('LPRCF: WorkerAuthService.getWorkerModel error: $e');
    }
    return null;
  }

  Future<WorkerModel> signUpWorker({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String cnic,
    required WorkerCategory category,
    required String city,
    required String address,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final worker = WorkerModel(
      workerId: cred.user!.uid,
      name: name,
      email: email,
      phone: phone,
      cnic: cnic,
      category: category,
      city: city,
      address: address,
      status: WorkerStatus.pending,
      createdAt: DateTime.now(),
    );

    await _db
        .collection('workers')
        .doc(cred.user!.uid)
        .set(worker.toMap());

    return worker;
  }

  Future<WorkerModel?> signInWorker(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return getWorkerModel(cred.user!.uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
