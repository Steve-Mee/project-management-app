import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:project_management_app/core/providers/mirror_runtime_config_provider.dart';
import 'package:project_management_app/features/mirror/private_grpc_backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Mirror private gRPC runtime config', () {
    test('rejects implicit localhost defaults in production validation', () {
      const config = MirrorPrivateGrpcRuntimeConfig(
        host: '127.0.0.1',
        port: 50051,
        timeout: Duration(seconds: 30),
        useTls: true,
        endpointSource: MirrorPrivateGrpcEndpointSource.defaultLocalhost,
      );

      expect(() => config.validate(productionBuild: true), throwsStateError);
    });

    test('rejects insecure transport in production validation', () {
      const config = MirrorPrivateGrpcRuntimeConfig(
        host: 'grpc.internal.example',
        port: 443,
        timeout: Duration(seconds: 30),
        useTls: false,
        endpointSource: MirrorPrivateGrpcEndpointSource.explicit,
      );

      expect(() => config.validate(productionBuild: true), throwsStateError);
    });

    test('allows explicit TLS configuration in production validation', () {
      const config = MirrorPrivateGrpcRuntimeConfig(
        host: 'grpc.internal.example',
        port: 443,
        timeout: Duration(seconds: 30),
        useTls: true,
        endpointSource: MirrorPrivateGrpcEndpointSource.explicit,
      );

      expect(() => config.validate(productionBuild: true), returnsNormally);
    });

    test('backend blocks insecure production transport when production runtime is forced', () {
      expect(
        () => PrivateGrpcBackend(
          client: SupabaseClient('https://example.supabase.co', 'anon-key'),
          host: '127.0.0.1',
          port: 50051,
          credentials: const ChannelCredentials.insecure(),
          productionRuntime: true,
        ),
        throwsStateError,
      );
    });
  });
}
