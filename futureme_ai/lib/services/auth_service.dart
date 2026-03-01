import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Stream of User
  Stream<User?> get user {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      debugPrint('AuthService: Firebase not initialized: $e');
      return const Stream.empty();
    }
  }

  // Sign in with Email and Password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Error signing in: $e');
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
      debugPrint('Error registering: $e');
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
      debugPrint('Error getting user model: $e');
    }
    return null;
  }
}
