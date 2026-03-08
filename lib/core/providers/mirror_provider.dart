library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/mirror/cloud_fly_backend.dart';
import '../../features/mirror/edge_function_backend.dart';
import '../../features/mirror/mirror_compute_backend.dart';
import '../../features/mirror/private_grpc_backend.dart';

export '../../features/mirror/cloud_fly_backend.dart';
export '../../features/mirror/edge_function_backend.dart';
export '../../features/mirror/mirror_compute_backend.dart';
export '../../features/mirror/private_grpc_backend.dart';

class MirrorState {
  const MirrorState({
    required this.mode,
    required this.isPremium,
  });

  final String mode;
  final bool isPremium;

  MirrorState copyWith({
    String? mode,
    bool? isPremium,
  }) {
    return MirrorState(
      mode: mode ?? this.mode,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

final mirrorModeProvider = StateProvider<String>((ref) => 'private');

final mirrorPremiumProvider = Provider<bool>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return _isPremiumUser(user);
});

final mirrorBackendProvider = Provider<MirrorComputeBackend>((ref) {
  final mode = ref.watch(mirrorModeProvider);
  final isPremium = ref.watch(mirrorPremiumProvider);

  if (mode == 'cloud' && isPremium) {
    return CloudFlyBackend();
  }

  if (mode == 'cloud' && !isPremium) {
    return EdgeFunctionBackend();
  }

  return PrivateGrpcBackend();
});

class MirrorNotifier extends Notifier<MirrorState> {
  @override
  MirrorState build() {
    final mode = ref.watch(mirrorModeProvider);
    final isPremium = ref.watch(mirrorPremiumProvider);
    return MirrorState(mode: mode, isPremium: isPremium);
  }

  void setMode(String mode) {
    if (mode != 'private' && mode != 'cloud') {
      return;
    }
    ref.read(mirrorModeProvider.notifier).state = mode;
    state = state.copyWith(mode: mode);
  }

  void refreshPremiumFromMetadata() {
    final isPremium = ref.read(mirrorPremiumProvider);
    state = state.copyWith(isPremium: isPremium);
  }
}

final mirrorProvider = NotifierProvider<MirrorNotifier, MirrorState>(MirrorNotifier.new);

bool _isPremiumUser(User? user) {
  if (user == null) {
    return false;
  }

  final appMetadata = user.appMetadata;
  final userMetadata = user.userMetadata;

  final planValue =
      appMetadata['plan'] ??
      appMetadata['subscription'] ??
      userMetadata?['plan'] ??
      userMetadata?['subscription'];

  final normalized = planValue?.toString().toLowerCase().trim() ?? '';
  return normalized == 'premium' || normalized == 'pro' || normalized == 'enterprise';
}
