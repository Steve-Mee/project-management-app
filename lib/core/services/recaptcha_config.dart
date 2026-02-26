import 'package:flutter_gcaptcha_v3/recaptca_config.dart';
import 'package:project_management_app/core/repository/settings_repository.dart';

/// reCAPTCHA configuration for issue 040-authentication-security-enhancements
/// Centralizes reCAPTCHA site key management and initialization
class RecaptchaConfig {
  static SettingsRepository? _settings;

  /// Initialize with settings repository (call during app startup)
  static void initializeWithRepository(SettingsRepository settings) {
    _settings = settings;
  }

  /// Get the reCAPTCHA site key from settings or fallback to empty string
  static String get siteKey => _settings?.getRecaptchaSiteKey() ?? '';

  /// Check if running in production mode (site key configured)
  static bool get isProduction => siteKey.isNotEmpty;

  /// Initialize reCAPTCHA handler if in production mode
  static void initialize() {
    if (isProduction) {
      RecaptchaHandler.instance.setupSiteKey(dataSiteKey: siteKey);
    }
  }
}

/*
REUSABLE UI EXAMPLE CODE FOR SETTINGS SCREEN (ADMIN ONLY)
Issue: .github/issues/040-authentication-security-enhancements.md

Add this to your settings screen widget (admin access required):

```dart
// In your settings screen state
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _recaptchaController = TextEditingController();
  bool _isAdmin = false; // Check user role here

  @override
  void initState() {
    super.initState();
    // Load current site key
    final settings = ref.read(settingsRepositoryProvider).value;
    if (settings != null) {
      _recaptchaController.text = settings.getRecaptchaSiteKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          // ... other settings ...

          // reCAPTCHA Site Key (Admin only, obscured)
          if (_isAdmin || kDebugMode) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _recaptchaController,
                obscureText: true, // Hide the key for security
                decoration: InputDecoration(
                  labelText: l10n.recaptcha_site_key,
                  hintText: l10n.recaptcha_site_key_hint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _saveRecaptchaKey,
                child: const Text('Save reCAPTCHA Key'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveRecaptchaKey() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider.future);
      await settings.setRecaptchaSiteKey(_recaptchaController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('reCAPTCHA key saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save reCAPTCHA key: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _recaptchaController.dispose();
    super.dispose();
  }
}
```
*/
