// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/mirror_premium_service.dart';

final mirrorPremiumServiceProvider = Provider<MirrorPremiumService>((ref) {
  return MirrorPremiumService();
});

final mirrorPremiumProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.watch(mirrorPremiumServiceProvider);
  return premiumService.isPremium();
});
