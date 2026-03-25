import 'package:project_management_app/generated/app_localizations.dart';

import 'models/mirror_launch_result.dart';

String mirrorLaunchFailureMessage(
  AppLocalizations l10n,
  MirrorLaunchResult result,
) {
  switch (result.status) {
    case MirrorLaunchStatus.featureDisabled:
      return l10n.mirrorFeatureDisabled;
    case MirrorLaunchStatus.permissionDenied:
      return l10n.mirrorPermissionDenied;
    case MirrorLaunchStatus.entitlementDenied:
      return l10n.mirrorCloudModeRequiresPremiumWarning;
    case MirrorLaunchStatus.launched:
    case MirrorLaunchStatus.launchedWithDowngrade:
      return l10n.mirrorUnavailableForAccount;
  }
}
