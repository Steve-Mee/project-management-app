import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';

import 'mirror_feature_flag_provider.dart';

/// Result of the central Mirror route/deeplink guard.
///
/// Consumers should render based on this value rather than duplicating
/// the feature-flag + permission check inline.
enum MirrorRouteGuardResult {
  /// Feature enabled and user has permission: allow navigation.
  allowed,

  /// Mirror feature flag is disabled for this account/environment.
  featureDisabled,

  /// Feature is enabled but the user lacks the `use_mirror` permission.
  permissionDenied,

  /// Guard is still resolving (async feature-flag check in progress).
  loading,
}

/// A single, mockable provider that centralises all Mirror access checks.
///
/// Replace [mirrorDeeplinkEnabledProvider] in [ProjectsInitializer] and use
/// this provider in the GoRoute builder instead of inline guard logic.
final mirrorRouteGuardProvider =
    FutureProvider<MirrorRouteGuardResult>((ref) async {
  final mirrorEnabled = await resolveMirrorFeatureEnabled(ref);
  if (!mirrorEnabled) {
    return MirrorRouteGuardResult.featureDisabled;
  }

  final canUseMirror = ref.read(
    hasPermissionProvider(AppPermissions.useMirror),
  );
  if (!canUseMirror) {
    return MirrorRouteGuardResult.permissionDenied;
  }

  return MirrorRouteGuardResult.allowed;
});
