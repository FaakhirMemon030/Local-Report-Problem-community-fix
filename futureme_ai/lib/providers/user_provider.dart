import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  late final AuthService _authService;
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  UserProvider() {
    _authService = AuthService();
    _init();
  }

  void _init() {
    _authService.user.listen((user) async {
      if (user != null) {
        await fetchUserModel(user.uid);
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUserModel(String uid) async {
    _isLoading = true;
    notifyListeners();
    _userModel = await _authService.getUserModel(uid);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final result = await _authService.signInWithEmailAndPassword(email, password);
    _isLoading = false;
    notifyListeners();
    return result != null;
  }

  Future<void> signUp(UserModel userModel, String password) async {
    _isLoading = true;
    notifyListeners();
    await _authService.registerWithEmailAndPassword(userModel, password);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
