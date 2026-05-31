import 'package:shared_preferences/shared_preferences.dart';

import '../constants/local_users.dart';
import '../models/app_user.dart';

class AuthService {
  static const _sessionKey = 'logged_username';

  Future<AppUser> signInWithUsername(String username, String password) async {
    final name = username.trim();
    if (name.isEmpty) throw Exception('أدخل اسم المستخدم');

    final local = findLocalUser(name);
    if (local == null) {
      throw Exception('اسم المستخدم "$name" غير موجود');
    }
    if (password != local.password) {
      throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, name);
    return local.toAppUser();
  }

  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_sessionKey);
    if (name == null) return null;

    final local = findLocalUser(name);
    if (local == null) {
      await signOut();
      return null;
    }
    return local.toAppUser();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
