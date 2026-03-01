import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userModel != null;
  String? get currentUserId => _userModel?.userId;

  AuthProvider() {
    _authService.user.listen((User? user) async {
      if (user != null) {
        _userModel = await _authService.getCurrentUserModel();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
      _userModel = await _authService.getCurrentUserModel();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String city,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signUp(email: email, password: password, name: name, city: city);
      _userModel = await _authService.getCurrentUserModel();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<void> updateName(String newName) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updateName(newName);
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(name: newName);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updatePassword(newPassword);
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(password: newPassword);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
