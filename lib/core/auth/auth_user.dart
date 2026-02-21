class AppUser {
  final String username;
  final String password;
  final String roleId;

  const AppUser({
    required this.username,
    required this.password,
    this.roleId = 'role_member',
  });

  Map<String, String> toMap() {
    return {
      'username': username,
      'password': password,
      'roleId': roleId,
    };
  }

  static AppUser fromMap(Map<String, dynamic> map) {
    return AppUser(
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      roleId: map['roleId'] as String? ?? 'role_member',
    );
  }
}
