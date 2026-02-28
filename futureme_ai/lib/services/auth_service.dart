import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of User
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with Email and Password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Register with Email and Password
  Future<UserCredential?> registerWithEmailAndPassword(UserModel userModel, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: password,
      );

      // Create user document in Firestore
      await _db.collection('users').doc(credential.user!.uid).set(userModel.toMap());

      return credential;
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user model
  Future<UserModel?> getUserModel(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting user model: $e');
    }
    return null;
  }
}
