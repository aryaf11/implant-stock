import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'user_repository.dart';

class AuthService {
  AuthService(this._users);

  final UserRepository _users;
  static const _sessionKey = 'logged_username';

  Future<AppUser> signInWithUsername(String username, String password) async {
    final name = username.trim();
    if (name.isEmpty) throw Exception('أدخل اسم المستخدم');

    final stored = await _users.findByUsername(name);
    if (stored == null) {
      throw Exception('اسم المستخدم "$name" غير موجود');
    }
    if (password != stored.password) {
      throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, name);
    return stored.toAppUser();
  }

  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_sessionKey);
    if (name == null) return null;

    final stored = await _users.findByUsername(name);
    if (stored == null) {
      await signOut();
      return null;
    }
    return stored.toAppUser();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
