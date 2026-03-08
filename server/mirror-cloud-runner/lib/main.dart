import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final server = Server.create(
    services: <Service>[MirrorCompileStubService()],
    codecRegistry: CodecRegistry(codecs: const <Codec>[GzipCodec(), IdentityCodec()]),
  );

  await server.serve(address: '0.0.0.0', port: port);
  stdout.writeln('mirror-cloud-runner gRPC stub listening on port $port');

  ProcessSignal.sigint.watch().listen((_) async {
    await server.shutdown();
    exit(0);
  });
}

class MirrorCompileStubService extends Service {
  @override
  String get $name => 'mirror.compute.v1.MirrorComputeService';

  MirrorCompileStubService() {
    $addMethod(ServiceMethod<List<int>, List<int>>(
      'Compile',
      compile,
      false,
      false,
      (List<int> value) => value,
      (List<int> value) => value,
    ));
  }

  Future<List<int>> compile(ServiceCall call, List<int> requestBytes) async {
    final raw = utf8.decode(requestBytes);
    final parsed = _tryParseJson(raw);

    final response = <String, dynamic>{
      'success': true,
      'output': 'Compile endpoint stub reached',
      'errors': <String>[],
      'warnings': <String>[],
      'echo': <String, dynamic>{
        'prompt': parsed['prompt'],
        'projectId': parsed['projectId'] ?? parsed['project_id'],
        'taskId': parsed['taskId'] ?? parsed['task_id'],
        'mode': parsed['mode'],
      },
    };

    return utf8.encode(jsonEncode(response));
  }

  Map<String, dynamic> _tryParseJson(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'raw': value};
    } catch (_) {
      return <String, dynamic>{'raw': value};
    }
  }
}
