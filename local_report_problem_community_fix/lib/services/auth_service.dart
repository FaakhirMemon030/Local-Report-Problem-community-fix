import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserModel() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else if (user.email == 'admin@lrpcf.com') {
        // Auto-provision admin if document is missing
        UserModel adminModel = UserModel(
          userId: user.uid,
          name: 'Admin',
          email: user.email!,
          role: 'admin',
          city: 'Admin City',
          password: 'admin@1122',
          reputationScore: 100,
          totalReports: 0,
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(user.uid).set(adminModel.toMap());
        return adminModel;
      }
    }
    return null;
  }

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required String city,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        UserModel userModel = UserModel(
          userId: user.uid,
          name: name,
          email: email,
          role: email == 'admin@lrpcf.com' ? 'admin' : 'user',
          city: city,
          password: password,
          reputationScore: 0,
          totalReports: 0,
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(user.uid).set(userModel.toMap());
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateName(String newName) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({'name': newName});
    }
  }

  Future<void> updatePassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
      await _db.collection('users').doc(user.uid).update({'password': newPassword});
    }
  }

  Future<void> deleteAccount() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // 1. Delete user document from Firestore
      await _db.collection('users').doc(user.uid).delete();
      // 2. Delete user from Firebase Auth
      await user.delete();
    }
  }

  // Admin: Get all users stream
  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Admin: Update user ban status
  Future<void> updateUserBanStatus(String userId, bool isBanned) async {
    await _db.collection('users').doc(userId).update({'isBanned': isBanned});
  }
}
