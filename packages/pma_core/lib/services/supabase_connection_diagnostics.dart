import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_logger.dart';

class SupabaseConnectionDiagnostics {
  SupabaseConnectionDiagnostics._();

  static DateTime? _lastDiagnosticRun;

  static String _keyPreview(String? key) {
    if (key == null || key.isEmpty) {
      return 'missing';
    }
    if (key.length <= 10) {
      return '${key.substring(0, key.length.clamp(0, 4))}...';
    }
    return '${key.substring(0, 6)}...${key.substring(key.length - 4)}';
  }

  static String _safeError(Object error) {
    final text = error.toString();
    if (text.length <= 320) {
      return text;
    }
    return '${text.substring(0, 320)}...';
  }

  static bool _isThrottled({Duration window = const Duration(seconds: 45)}) {
    final now = DateTime.now();
    if (_lastDiagnosticRun != null && now.difference(_lastDiagnosticRun!) < window) {
      return true;
    }
    _lastDiagnosticRun = now;
    return false;
  }

  static Future<void> logConfigurationSnapshot({
    required String? url,
    required String? anonKey,
    required String context,
  }) async {
    final parsed = Uri.tryParse(url ?? '');
    AppLogger.debug(
      'Supabase config snapshot',
      params: {
        'context': context,
        'url_present': (url ?? '').isNotEmpty,
        'anon_key_present': (anonKey ?? '').isNotEmpty,
        'anon_key_preview': _keyPreview(anonKey),
        'url_scheme': parsed?.scheme,
        'url_host': parsed?.host,
        'url_port': parsed?.hasPort == true ? parsed!.port : null,
      },
    );
  }

  static Future<void> logNetworkDiagnostics({
    required String? url,
    required String context,
    Object? error,
    StackTrace? stackTrace,
    bool force = false,
  }) async {
    if (!force && _isThrottled()) {
      AppLogger.debug('Supabase diagnostics throttled', params: {'context': context});
      return;
    }

    final rawUrl = url ?? '';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.host.isEmpty) {
      AppLogger.warning(
        'Supabase diagnostics aborted: invalid URL',
        params: {'context': context, 'url': rawUrl},
      );
      if (error != null) {
        AppLogger.instance.w('Supabase error context: ${_safeError(error)}');
      }
      return;
    }

    AppLogger.debug(
      'Supabase diagnostics started',
      params: {
        'context': context,
        'url': rawUrl,
        'host': uri.host,
        'platform': defaultTargetPlatform.name,
        'error_type': error?.runtimeType.toString(),
      },
    );

    try {
      final results = await InternetAddress.lookup(uri.host).timeout(const Duration(seconds: 4));
      final addresses = results.map((e) => e.address).toList(growable: false);
      AppLogger.event(
        'supabase_dns_lookup_success',
        params: {
          'context': context,
          'host': uri.host,
          'addresses': addresses.join('|'),
          'address_count': addresses.length,
        },
      );
    } on SocketException catch (e) {
      AppLogger.warning(
        'Supabase DNS lookup failed',
        params: {
          'context': context,
          'host': uri.host,
          'socket_error': _safeError(e),
        },
      );
    } on TimeoutException {
      AppLogger.warning(
        'Supabase DNS lookup timeout',
        params: {'context': context, 'host': uri.host},
      );
    } catch (e) {
      AppLogger.warning(
        'Supabase DNS lookup unexpected failure',
        params: {
          'context': context,
          'host': uri.host,
          'error': _safeError(e),
        },
      );
    }

    await _probeEndpoint(uri, '/auth/v1/health', context);
    await _probeEndpoint(uri, '/rest/v1/', context);

    if (error != null) {
      AppLogger.warning(
        'Supabase request failed',
        params: {
          'context': context,
          'error_type': error.runtimeType.toString(),
          'error': _safeError(error),
        },
      );
    }
    if (stackTrace != null) {
      AppLogger.instance.d('Supabase failure stack: $stackTrace');
    }
  }

  static Future<void> _probeEndpoint(Uri baseUri, String path, String context) async {
    final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    final target = Uri.parse('$origin$path');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

    try {
      final request = await client.getUrl(target).timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      await response.drain<void>();
      AppLogger.event(
        'supabase_endpoint_probe',
        params: {
          'context': context,
          'endpoint': target.toString(),
          'status_code': response.statusCode,
        },
      );
    } on TimeoutException {
      AppLogger.warning(
        'Supabase endpoint probe timeout',
        params: {'context': context, 'endpoint': target.toString()},
      );
    } on SocketException catch (e) {
      AppLogger.warning(
        'Supabase endpoint probe socket failure',
        params: {
          'context': context,
          'endpoint': target.toString(),
          'socket_error': _safeError(e),
        },
      );
    } catch (e) {
      AppLogger.warning(
        'Supabase endpoint probe failed',
        params: {
          'context': context,
          'endpoint': target.toString(),
          'error': _safeError(e),
        },
      );
    } finally {
      client.close(force: true);
    }
  }
}
