import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    exitCode = 64;
    return;
  }

  final target = args.first.trim().toLowerCase();
  const supported = ['web', 'windows', 'macos', 'linux'];
  if (!supported.contains(target)) {
    stderr.writeln('Unsupported target: $target');
    _printUsage();
    exitCode = 64;
    return;
  }

  final process = await Process.start(
    'flutter',
    ['build', target],
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  exitCode = code;
}

void _printUsage() {
  stdout.writeln('Usage: dart run tool/build.dart <target>');
  stdout.writeln('Targets: web | windows | macos | linux');
}
