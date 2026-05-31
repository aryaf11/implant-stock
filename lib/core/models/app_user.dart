enum UserRole { admin, supervisor }

class AppUser {
  const AppUser({
    required this.username,
    required this.displayName,
    required this.role,
    this.centerId,
  });

  /// اسم المستخدم (admin, branch1, …)
  final String username;
  final String displayName;
  final UserRole role;
  final String? centerId;

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromDoc(String username, Map<String, dynamic> m) {
    final roleStr = m['role'] as String? ?? 'supervisor';
    return AppUser(
      username: username,
      displayName: m['displayName'] as String? ?? username,
      role: roleStr == 'admin' ? UserRole.admin : UserRole.supervisor,
      centerId: m['centerId'] as String?,
    );
  }
}
