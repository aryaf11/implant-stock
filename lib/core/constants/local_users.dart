import '../models/app_user.dart';

/// الحسابات الافتراضية — أدمن + الفروع (تُدمج تلقائياً عند التشغيل).
class LocalUser {
  const LocalUser({
    required this.username,
    required this.password,
    required this.displayName,
    required this.role,
    this.centerId,
  });

  final String username;
  final String password;
  final String displayName;
  final UserRole role;
  final String? centerId;

  AppUser toAppUser() => AppUser(
        username: username,
        displayName: displayName,
        role: role,
        centerId: centerId,
      );
}

const kLocalUsers = <LocalUser>[
  LocalUser(
    username: 'admin',
    password: '1387raghad',
    displayName: 'مسؤول المستودع',
    role: UserRole.admin,
  ),
  LocalUser(
    username: 'branch1',
    password: 'branch1@123',
    displayName: 'مشرف الفرع الأول',
    role: UserRole.supervisor,
    centerId: 'branch1',
  ),
  LocalUser(
    username: 'branch2',
    password: 'branch2@123',
    displayName: 'مشرف الفرع الثاني',
    role: UserRole.supervisor,
    centerId: 'branch2',
  ),
  LocalUser(
    username: 'branch3',
    password: 'branch3@123',
    displayName: 'مشرف الفرع الثالث',
    role: UserRole.supervisor,
    centerId: 'branch3',
  ),
  LocalUser(
    username: 'branch4',
    password: 'branch4@123',
    displayName: 'مشرف الفرع الرابع',
    role: UserRole.supervisor,
    centerId: 'branch4',
  ),
  LocalUser(
    username: 'dr.saleh',
    password: 'dr.saleh4710',
    displayName: 'د. صالح',
    role: UserRole.supervisor,
    centerId: 'drsaleh',
  ),
  LocalUser(
    username: 'nurse',
    password: 'nurse@123',
    displayName: 'ممرضة',
    role: UserRole.nurse,
    centerId: 'branch1',
  ),
];

LocalUser? findLocalUser(String username) {
  final name = username.trim();
  for (final u in kLocalUsers) {
    if (u.username == name) return u;
  }
  return null;
}
