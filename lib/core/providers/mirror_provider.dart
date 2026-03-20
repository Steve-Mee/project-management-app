// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
library;

export '../../features/mirror/mirror_compute_backend.dart';
export '../../features/mirror/mirror_gateway_backend.dart';
export '../../features/mirror/private_grpc_backend.dart';
export '../../features/mirror/services/mirror_context_budget_service.dart';
export 'mirror_entitlement_provider.dart';
export 'mirror_feature_flag_provider.dart';
export 'mirror_offline_cache_provider.dart';
