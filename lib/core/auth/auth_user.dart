import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String username,
    required String password,
    @Default('role_member') String roleId,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  Map<String, String> toMap() {
    return {
      'username': username,
      'password': password,
      'roleId': roleId,
    };
  }

  static AppUser fromMap(Map<String, dynamic> map) {
    return AppUser.fromJson(map);
  }
}
