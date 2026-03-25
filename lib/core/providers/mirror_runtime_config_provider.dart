library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

const bool _isMirrorProductionBuild = bool.fromEnvironment(
  'dart.vm.product',
  defaultValue: false,
);
const String _privateGrpcHostFromEnv = String.fromEnvironment(
  'MIRROR_PRIVATE_GRPC_HOST',
  defaultValue: '',
);
const String _privateGrpcPortFromEnv = String.fromEnvironment(
  'MIRROR_PRIVATE_GRPC_PORT',
  defaultValue: '',
);
const int _privateGrpcTimeoutMsFromEnv = int.fromEnvironment(
  'MIRROR_PRIVATE_GRPC_TIMEOUT_MS',
  defaultValue: 30000,
);
const bool _privateGrpcUseTlsFromEnv = bool.fromEnvironment(
  'MIRROR_PRIVATE_GRPC_USE_TLS',
  defaultValue: false,
);

enum MirrorPrivateGrpcEndpointSource {
  explicit,
  defaultLocalhost,
}

class MirrorPrivateGrpcRuntimeConfig {
  const MirrorPrivateGrpcRuntimeConfig({
    required this.host,
    required this.port,
    required this.timeout,
    required this.useTls,
    required this.endpointSource,
  });

  final String host;
  final int port;
  final Duration timeout;
  final bool useTls;
  final MirrorPrivateGrpcEndpointSource endpointSource;

  ChannelCredentials get channelCredentials => useTls
      ? const ChannelCredentials.secure()
      : const ChannelCredentials.insecure();

  bool get usesImplicitLocalDefaults =>
      endpointSource == MirrorPrivateGrpcEndpointSource.defaultLocalhost;

  void validate({bool productionBuild = _isMirrorProductionBuild}) {
    if (host.trim().isEmpty) {
      throw StateError('Mirror private gRPC host must not be empty.');
    }
    if (port < 1 || port > 65535) {
      throw StateError(
        'Mirror private gRPC port must be between 1 and 65535.',
      );
    }
    if (timeout <= Duration.zero) {
      throw StateError('Mirror private gRPC timeout must be positive.');
    }

    if (!productionBuild) {
      return;
    }

    if (usesImplicitLocalDefaults) {
      throw StateError(
        'Private gRPC runtime requires explicit MIRROR_PRIVATE_GRPC_HOST and '
        'MIRROR_PRIVATE_GRPC_PORT in production.',
      );
    }

    if (!useTls) {
      throw StateError(
        'Private gRPC runtime requires MIRROR_PRIVATE_GRPC_USE_TLS=true in production.',
      );
    }
  }
}

final mirrorPrivateGrpcRuntimeConfigProvider =
    Provider<MirrorPrivateGrpcRuntimeConfig>((ref) {
  final hasExplicitHost = _privateGrpcHostFromEnv.trim().isNotEmpty;
  final hasExplicitPort = _privateGrpcPortFromEnv.trim().isNotEmpty;
  if (hasExplicitHost != hasExplicitPort) {
    throw StateError(
      'Set both MIRROR_PRIVATE_GRPC_HOST and MIRROR_PRIVATE_GRPC_PORT together.',
    );
  }

  final config = MirrorPrivateGrpcRuntimeConfig(
    host: hasExplicitHost ? _privateGrpcHostFromEnv.trim() : '127.0.0.1',
    port: hasExplicitPort ? int.parse(_privateGrpcPortFromEnv.trim()) : 50051,
    timeout: const Duration(milliseconds: _privateGrpcTimeoutMsFromEnv),
    useTls: _privateGrpcUseTlsFromEnv,
    endpointSource: hasExplicitHost
        ? MirrorPrivateGrpcEndpointSource.explicit
        : MirrorPrivateGrpcEndpointSource.defaultLocalhost,
  );
  config.validate();
  return config;
});
