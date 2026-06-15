enum UserRole { admin, supervisor, nurse }

UserRole parseUserRole(String? roleStr) {
  switch (roleStr) {
    case 'admin':
      return UserRole.admin;
    case 'nurse':
      return UserRole.nurse;
    default:
      return UserRole.supervisor;
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.nurse:
      return 'nurse';
    case UserRole.supervisor:
      return 'supervisor';
  }
}

String userRoleLabelAr(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'أدمن';
    case UserRole.nurse:
      return 'ممرضة';
    case UserRole.supervisor:
      return 'مشرف';
  }
}

class AppUser {
  const AppUser({
    required this.username,
    required this.displayName,
    required this.role,
    this.centerId,
  });

  final String username;
  final String displayName;
  final UserRole role;
  final String? centerId;

  bool get isAdmin => role == UserRole.admin;
  bool get isNurse => role == UserRole.nurse;

  factory AppUser.fromDoc(String username, Map<String, dynamic> m) {
    return AppUser(
      username: username,
      displayName: m['displayName'] as String? ?? username,
      role: parseUserRole(m['role'] as String?),
      centerId: m['centerId'] as String?,
    );
  }
}
