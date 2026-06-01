import 'app_user.dart';

class StoredUser {
  const StoredUser({
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

  bool get isAdmin => role == UserRole.admin;

  AppUser toAppUser() => AppUser(
        username: username,
        displayName: displayName,
        role: role,
        centerId: centerId,
      );

  Map<String, dynamic> toMap() => {
        'username': username,
        'password': password,
        'displayName': displayName,
        'role': role == UserRole.admin ? 'admin' : 'supervisor',
        if (centerId != null) 'centerId': centerId,
      };

  factory StoredUser.fromMap(Map<String, dynamic> m) {
    final roleStr = m['role'] as String? ?? 'supervisor';
    return StoredUser(
      username: m['username'] as String? ?? '',
      password: m['password'] as String? ?? '',
      displayName: m['displayName'] as String? ?? '',
      role: roleStr == 'admin' ? UserRole.admin : UserRole.supervisor,
      centerId: m['centerId'] as String?,
    );
  }

  StoredUser copyWith({
    String? username,
    String? password,
    String? displayName,
    UserRole? role,
    String? centerId,
    bool clearCenterId = false,
  }) =>
      StoredUser(
        username: username ?? this.username,
        password: password ?? this.password,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        centerId: clearCenterId ? null : (centerId ?? this.centerId),
      );
}
