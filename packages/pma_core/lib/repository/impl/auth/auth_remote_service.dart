import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote auth service using Supabase.
class RemoteAuthService {
  Future<void> signIn(String username, String password, {String? captchaToken}) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: username.trim(),
      password: password,
      captchaToken: captchaToken,
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> registerUser(String username, String password) async {
    await Supabase.instance.client.auth.signUp(
      email: username.trim(),
      password: password,
    );
  }
}
