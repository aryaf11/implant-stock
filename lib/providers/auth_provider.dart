import 'package:flutter/foundation.dart';

import '../core/models/app_user.dart';
import '../core/services/auth_service.dart';
import '../core/utils/auth_errors.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth);

  final AuthService _auth;
  AppUser? _user;
  bool _initializing = false;
  bool _loggingIn = false;
  String? _error;

  AppUser? get user => _user;
  bool get isInitializing => _initializing;
  bool get isLoggingIn => _loggingIn;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> tryRestoreSession() async {
    _initializing = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _auth.restoreSession();
    } catch (e) {
      _error = mapAuthError(e);
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      _error = 'أدخل اسم المستخدم وكلمة المرور';
      notifyListeners();
      return false;
    }

    _loggingIn = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _auth.signInWithUsername(username, password);
      return true;
    } catch (e) {
      _user = null;
      _error = mapAuthError(e);
      return false;
    } finally {
      _loggingIn = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }
}
