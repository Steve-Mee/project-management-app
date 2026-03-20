library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';
import 'package:pma_core/core/providers/feature_flag_provider.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';

const bool _mirrorFeatureFlagStrictEnv = bool.fromEnvironment(
  'MIRROR_FEATURE_FLAG_STRICT',
);

const bool _isProductionBuild = bool.fromEnvironment('dart.vm.product');

bool _isMirrorFeatureFlagStrictModeEnabled() {
  return _mirrorFeatureFlagStrictEnv && _isProductionBuild;
}

bool _mirrorFeatureFlagDefaultValue() {
  return _isMirrorFeatureFlagStrictModeEnabled() ? false : true;
}

Future<bool> resolveMirrorFeatureEnabled(
  Ref ref, {
  bool useWatch = false,
}) async {
  final flagsAsync = useWatch
      ? ref.watch(featureFlagProvider)
      : ref.read(featureFlagProvider);
  final defaultValue = _mirrorFeatureFlagDefaultValue();
  final syncResolved = flagsAsync.maybeWhen(
    data: (flags) =>
        FeatureFlagResolver.isEnabled(flags, 'mirror_enabled', defaultValue: defaultValue),
    orElse: () => null,
  );

  if (syncResolved != null) {
    return syncResolved;
  }

  try {
    if (useWatch) {
      await ref.watch(featureFlagProvider.future);
    } else {
      await ref.read(featureFlagProvider.future);
    }

    return FeatureFlagResolver.isEnabled(
      ref.read(featureFlagProvider).valueOrNull ?? const <String, dynamic>{},
      'mirror_enabled',
      defaultValue: defaultValue,
    );
  } catch (_) {
    return defaultValue;
  }
}

Future<bool> resolveMirrorPrivateModeEnabled(
  Ref ref, {
  bool useWatch = false,
}) async {
  return _resolveBooleanFeatureFlag(
    ref,
    key: 'mirror_private_mode_enabled',
    defaultValue: true,
    useWatch: useWatch,
  );
}

Future<bool> resolveMirrorCloudModeEnabled(
  Ref ref, {
  bool useWatch = false,
}) async {
  return _resolveBooleanFeatureFlag(
    ref,
    key: 'mirror_cloud_mode_enabled',
    defaultValue: true,
    useWatch: useWatch,
  );
}

Future<bool> resolveMirrorAdminBypassEnabled(
  Ref ref, {
  bool useWatch = false,
}) async {
  final canManageRoles = useWatch
      ? ref.watch(hasPermissionProvider(AppPermissions.manageRoles))
      : ref.read(hasPermissionProvider(AppPermissions.manageRoles));
  final canManageUsers = useWatch
      ? ref.watch(hasPermissionProvider(AppPermissions.manageUsers))
      : ref.read(hasPermissionProvider(AppPermissions.manageUsers));
  final canUseBypass = canManageRoles || canManageUsers;
  if (!canUseBypass) {
    return false;
  }

  return _resolveBooleanFeatureFlag(
    ref,
    key: 'mirror_admin_testing_bypass',
    defaultValue: false,
    useWatch: useWatch,
  );
}

Future<bool> _resolveBooleanFeatureFlag(
  Ref ref, {
  required String key,
  required bool defaultValue,
  bool useWatch = false,
}) async {
  final flagsAsync = useWatch
      ? ref.watch(featureFlagProvider)
      : ref.read(featureFlagProvider);
  final syncResolved = flagsAsync.maybeWhen(
    data: (flags) =>
        FeatureFlagResolver.isEnabled(flags, key, defaultValue: defaultValue),
    orElse: () => null,
  );

  if (syncResolved != null) {
    return syncResolved;
  }

  try {
    if (useWatch) {
      await ref.watch(featureFlagProvider.future);
    } else {
      await ref.read(featureFlagProvider.future);
    }
    return FeatureFlagResolver.isEnabled(
      ref.read(featureFlagProvider).valueOrNull ?? const <String, dynamic>{},
      key,
      defaultValue: defaultValue,
    );
  } catch (_) {
    return defaultValue;
  }
}
