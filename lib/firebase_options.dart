import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Placeholder Firebase options file.
///
/// This project currently uses native platform Firebase configuration
/// for `Firebase.initializeApp()` in `main.dart`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web in this project.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not used. '
          'This project initializes Firebase via native platform files.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Unsupported platform.');
    }
  }
}
