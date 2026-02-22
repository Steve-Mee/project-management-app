import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:animate_do/animate_do.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/theme_providers.dart';

/// Login screen for basic authentication.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _submitting = false;
  bool _showPassword = false;
  bool _enableAutoLogin = false;
  bool _usePasswordLogin = false;
  bool? _biometricAvailable;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_biometricAvailable == null) {
      ref.read(authProvider.notifier).isBiometricAvailable().then((value) {
        if (mounted) setState(() => _biometricAvailable = value);
      });
    }
  }

  Future<void> _submitLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar(l10n.loginMissingCredentials);
      return;
    }

    setState(() {
      _submitting = true;
    });

    final success = await ref
        .read(authProvider.notifier)
        .login(username, password, enableAutoLogin: _enableAutoLogin);
    if (!success) {
      _showSnackBar(l10n.loginFailedMessage);
    } else {
      // Check if biometric can be enabled
      final biometricAvailable = await ref.read(authProvider.notifier).isBiometricAvailable();
      final biometricEnabled = ref.read(biometricLoginProvider).maybeWhen(
        data: (enabled) => enabled,
        orElse: () => false,
      );
      if (biometricAvailable && !biometricEnabled) {
        await _showBiometricDialog();
      }
    }

    if (mounted) {
      setState(() {
        _submitting = false;
      });
    }
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showRegisterDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final repeatController = TextEditingController();
    var showPassword = false;
    var showRepeatPassword = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final username = usernameController.text.trim();
          final password = passwordController.text;
          final repeatPassword = repeatController.text;
          final hasMinLength = password.length >= 8;
          final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
          final hasDigit = RegExp(r'\d').hasMatch(password);
          final matches = password.isNotEmpty && password == repeatPassword;
          final canSubmit =
              username.isNotEmpty &&
              hasMinLength &&
              hasLetter &&
              hasDigit &&
              matches;

          return AlertDialog(
            title: Text(l10n.registerTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(labelText: l10n.usernameLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: repeatController,
                  obscureText: !showRepeatPassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.repeatPasswordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(
                        showRepeatPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showRepeatPassword = !showRepeatPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.passwordRulesTitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRuleRow(
                  context,
                  l10n.passwordRuleMinLength,
                  hasMinLength,
                ),
                _buildRuleRow(context, l10n.passwordRuleHasLetter, hasLetter),
                _buildRuleRow(context, l10n.passwordRuleHasDigit, hasDigit),
                _buildRuleRow(context, l10n.passwordRuleMatches, matches),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancelButton),
              ),
              TextButton(
                onPressed: canSubmit
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: Text(l10n.registerButton),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) {
      usernameController.dispose();
      passwordController.dispose();
      repeatController.dispose();
      return;
    }

    final username = usernameController.text.trim();
    final password = passwordController.text;
    final repeatPassword = repeatController.text;
    final hasMinLength = password.length >= 8;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final matches = password == repeatPassword;

    if (username.isEmpty ||
        !hasMinLength ||
        !hasLetter ||
        !hasDigit ||
        !matches) {
      if (mounted) {
        final issues = <String>[];
        if (username.isEmpty) {
          issues.add(l10n.registrationIssueUsernameMissing);
        }
        if (!hasMinLength) {
          issues.add(l10n.registrationIssueMinLength);
        }
        if (!hasLetter) {
          issues.add(l10n.registrationIssueLetter);
        }
        if (!hasDigit) {
          issues.add(l10n.registrationIssueDigit);
        }
        if (!matches) {
          issues.add(l10n.registrationIssueNoMatch);
        }
        _showSnackBar(l10n.registrationFailedWithIssues(issues.join(', ')));
      }
      usernameController.dispose();
      passwordController.dispose();
      repeatController.dispose();
      return;
    }

    final added = await ref
        .read(authProvider.notifier)
        .signUp(username, password);

    if (!mounted) {
      usernameController.dispose();
      passwordController.dispose();
      repeatController.dispose();
      return;
    }

    if (added) {
      _usernameController.text = usernameController.text.trim();
      _passwordController.text = '';
      _showSnackBar(l10n.accountCreatedMessage);
    } else {
      _showSnackBar(l10n.registerFailedMessage);
    }

    usernameController.dispose();
    passwordController.dispose();
    repeatController.dispose();
  }

  Future<void> _showBiometricDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.enableBiometricDialogTitle),
        content: Text(l10n.enableBiometricDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.enableBiometricDialogNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.enableBiometricDialogYes),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final enrolled = await ref
          .read(authProvider.notifier)
          .enrollBiometrics(username, password);
      if (enrolled) {
        await ref.read(biometricLoginProvider.notifier).setEnabled(true);
        _showSnackBar(l10n.biometric_enroll_success);
      } else {
        _showSnackBar(l10n.biometric_auth_failed);
      }
    }
  }

  Future<void> _authenticateBiometric() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    final success = await ref.read(authProvider.notifier).authenticateWithBiometrics();
    if (!success) {
      _showSnackBar(l10n.biometric_auth_failed);
    }
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  Widget _buildRuleRow(BuildContext context, String label, bool satisfied) {
    final color = satisfied
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final biometricEnabled = ref.watch(biometricLoginProvider).maybeWhen(
      data: (enabled) => enabled,
      orElse: () => false,
    );
    if (_biometricAvailable == null) {
      ref.read(authProvider.notifier).isBiometricAvailable().then((value) {
        if (mounted) setState(() => _biometricAvailable = value);
      });
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.appTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1976D2), // Blue
                      Color(0xFF42A5F5), // Lighter blue
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip:
                    AppLocalizations.of(context)?.logoutTooltip ?? 'Uitloggen',
                onPressed: () async {
                  final l10n = AppLocalizations.of(context)!;
                  await ref.read(authProvider.notifier).logout();
                  if (!mounted) {
                    return;
                  }
                  _showSnackBar(l10n.loggedOutMessage);
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip:
                    AppLocalizations.of(context)?.closeAppTooltip ??
                    'App sluiten',
                onPressed: () {
                  if (Platform.isAndroid || Platform.isIOS) {
                    SystemNavigator.pop();
                  } else {
                    windowManager.close();
                  }
                },
              ),
            ],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.loginTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            initialValue: locale.maybeWhen(
                              data: (loc) => loc?.languageCode,
                              orElse: () => null,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.languageLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(l10n.languageSystem),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(l10n.languageEnglish),
                              ),
                              DropdownMenuItem(
                                value: 'nl',
                                child: Text(l10n.languageDutch),
                              ),
                              DropdownMenuItem(
                                value: 'es',
                                child: Text(l10n.languageSpanish),
                              ),
                              DropdownMenuItem(
                                value: 'fr',
                                child: Text(l10n.languageFrench),
                              ),
                              DropdownMenuItem(
                                value: 'de',
                                child: Text(l10n.languageGerman),
                              ),
                              DropdownMenuItem(
                                value: 'pt',
                                child: Text(l10n.languagePortuguese),
                              ),
                              DropdownMenuItem(
                                value: 'it',
                                child: Text(l10n.languageItalian),
                              ),
                              DropdownMenuItem(
                                value: 'ar',
                                child: Text(l10n.languageArabic),
                              ),
                              DropdownMenuItem(
                                value: 'zh',
                                child: Text(l10n.languageChinese),
                              ),
                              DropdownMenuItem(
                                value: 'ja',
                                child: Text(l10n.languageJapanese),
                              ),
                              DropdownMenuItem(
                                value: 'ko',
                                child: Text(l10n.languageKorean),
                              ),
                              DropdownMenuItem(
                                value: 'ru',
                                child: Text(l10n.languageRussian),
                              ),
                              DropdownMenuItem(
                                value: 'hi',
                                child: Text(l10n.languageHindi),
                              ),
                            ],
                            onChanged: (value) {
                              ref
                                  .read(localeProvider.notifier)
                                  .setLocaleCode(value);
                            },
                          ),
                          const SizedBox(height: 24),
                          if (biometricEnabled && (_biometricAvailable ?? false) && !_usePasswordLogin) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitting ? null : _authenticateBiometric,
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.fingerprint),
                                          const SizedBox(width: 8),
                                          Text(l10n.loginWithBiometric),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => setState(() => _usePasswordLogin = true),
                                child: Text(l10n.use_password_instead),
                              ),
                            ),
                          ] else ...[
                            TextField(
                              key: const ValueKey('login_username'),
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: l10n.usernameLabel,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.person),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              key: const ValueKey('login_password'),
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submitLogin(),
                              decoration: InputDecoration(
                                labelText: l10n.passwordLabel,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            CheckboxListTile(
                              value: _enableAutoLogin,
                              onChanged: (value) {
                                setState(() {
                                  _enableAutoLogin = value ?? false;
                                });
                              },
                              title: const Text('Auto-login inschakelen'),
                              subtitle: const Text(
                                'Automatisch inloggen bij volgende app start',
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                key: const ValueKey('login_button'),
                                onPressed: _submitting ? null : _submitLogin,
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(l10n.loginButton),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _submitting ? null : _showRegisterDialog,
                            child: Text(l10n.createAccount),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
