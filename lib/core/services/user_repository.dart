import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/local_users.dart';
import '../models/app_user.dart';
import '../models/stored_user.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  SharedPreferences? _prefs;
  static const _key = 'implant_stock_users_v1';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _syncDefaults(persistIfMissing: true);
  }

  /// إضافة حسابات جديدة من الافتراضي دون حذف الموجود.
  Future<void> ensureDefaults() async {
    await _syncDefaults(persistIfMissing: true);
  }

  bool _hasUsername(List<StoredUser> users, String username) {
    final name = username.trim().toLowerCase();
    return users.any((u) => u.username.trim().toLowerCase() == name);
  }

  Future<List<StoredUser>> _readFromPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) {
      return kLocalUsers.map(_fromLocal).toList();
    }
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => StoredUser.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// يدمج الحسابات الافتراضية الناقصة ويعيد القائمة الكاملة.
  Future<List<StoredUser>> _syncDefaults({required bool persistIfMissing}) async {
    final all = await _readFromPrefs();
    var changed = false;
    for (final u in kLocalUsers) {
      if (_hasUsername(all, u.username)) continue;
      all.add(_fromLocal(u));
      changed = true;
    }
    if (changed && persistIfMissing) {
      await _saveAll(all);
    }
    return all;
  }

  StoredUser _fromLocal(LocalUser u) => StoredUser(
        username: u.username,
        password: u.password,
        displayName: u.displayName,
        role: u.role,
        centerId: u.centerId,
      );

  Future<List<StoredUser>> loadAll() async {
    final all = await _syncDefaults(persistIfMissing: true);
    return List.unmodifiable(all);
  }

  Future<StoredUser?> findByUsername(String username) async {
    final name = username.trim();
    final all = await loadAll();
    for (final u in all) {
      if (u.username == name) return u;
    }
    return null;
  }

  Future<void> _saveAll(List<StoredUser> users) async {
    _prefs ??= await SharedPreferences.getInstance();
    final payload = jsonEncode(users.map((e) => e.toMap()).toList());
    final ok = await _prefs!.setString(_key, payload);
    if (!ok) {
      throw Exception('تعذر حفظ بيانات المستخدمين في المتصفح');
    }
  }

  Future<void> addUser(StoredUser user) async {
    final all = [...await loadAll()];
    if (user.username.trim().isEmpty) {
      throw Exception('اسم المستخدم مطلوب');
    }
    if (all.any((u) => u.username == user.username)) {
      throw Exception('اسم المستخدم موجود مسبقاً');
    }
    if (user.password.isEmpty) throw Exception('كلمة المرور مطلوبة');
    if (user.role == UserRole.supervisor &&
        (user.centerId == null || user.centerId!.isEmpty)) {
      throw Exception('اختر الفرع للمشرف');
    }
    all.add(user);
    await _saveAll(all);
  }

  Future<void> updateUser(
    String username, {
    String? password,
    String? displayName,
    UserRole? role,
    String? centerId,
    bool clearCenterId = false,
  }) async {
    final all = [...await loadAll()];
    final i = all.indexWhere((u) => u.username == username);
    if (i < 0) throw Exception('المستخدم غير موجود');
    var u = all[i];
    if (password != null && password.isNotEmpty) {
      u = u.copyWith(password: password);
    }
    if (displayName != null) u = u.copyWith(displayName: displayName);
    if (role != null) u = u.copyWith(role: role);
    if (clearCenterId) {
      u = u.copyWith(clearCenterId: true);
    } else if (centerId != null) {
      u = u.copyWith(centerId: centerId);
    }
    if (u.role == UserRole.supervisor &&
        (u.centerId == null || u.centerId!.isEmpty)) {
      throw Exception('المشرف يحتاج فرعاً');
    }
    all[i] = u;
    await _saveAll(all);
  }

  Future<void> deleteUser(String username) async {
    final all = [...await loadAll()];
    final admins = all.where((u) => u.isAdmin).length;
    StoredUser? target;
    for (final u in all) {
      if (u.username == username) {
        target = u;
        break;
      }
    }
    if (target == null) throw Exception('المستخدم غير موجود');
    if (target.isAdmin && admins <= 1) {
      throw Exception('لا يمكن حذف آخر حساب أدمن');
    }
    all.removeWhere((u) => u.username == username);
    await _saveAll(all);
  }

  Future<void> resetToDefaults() async {
    await _saveAll(kLocalUsers.map(_fromLocal).toList());
    if (kDebugMode) debugPrint('[UserRepository] reset to defaults');
  }
}
