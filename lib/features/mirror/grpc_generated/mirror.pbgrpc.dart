// This is a generated file - do not edit.
//
// Generated from mirror.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mirror.pb.dart' as $0;

export 'mirror.pb.dart';

@$pb.GrpcServiceName('mirror.compute.v1.MirrorComputeService')
class MirrorComputeServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MirrorComputeServiceClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.CompileResponse> compile(
    $0.CompileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$compile, request, options: options);
  }

  $grpc.ResponseFuture<$0.ApplyResponse> apply(
    $0.ApplyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$apply, request, options: options);
  }

  // method descriptors

  static final _$compile =
      $grpc.ClientMethod<$0.CompileRequest, $0.CompileResponse>(
          '/mirror.compute.v1.MirrorComputeService/Compile',
          ($0.CompileRequest value) => value.writeToBuffer(),
          $0.CompileResponse.fromBuffer);
  static final _$apply = $grpc.ClientMethod<$0.ApplyRequest, $0.ApplyResponse>(
      '/mirror.compute.v1.MirrorComputeService/Apply',
      ($0.ApplyRequest value) => value.writeToBuffer(),
      $0.ApplyResponse.fromBuffer);
}

@$pb.GrpcServiceName('mirror.compute.v1.MirrorComputeService')
abstract class MirrorComputeServiceBase extends $grpc.Service {
  $core.String get $name => 'mirror.compute.v1.MirrorComputeService';

  MirrorComputeServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CompileRequest, $0.CompileResponse>(
        'Compile',
        compile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CompileRequest.fromBuffer(value),
        ($0.CompileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ApplyRequest, $0.ApplyResponse>(
        'Apply',
        apply_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ApplyRequest.fromBuffer(value),
        ($0.ApplyResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.CompileResponse> compile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CompileRequest> $request) async {
    return compile($call, await $request);
  }

  $async.Future<$0.CompileResponse> compile(
      $grpc.ServiceCall call, $0.CompileRequest request);

  $async.Future<$0.ApplyResponse> apply_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ApplyRequest> $request) async {
    return apply($call, await $request);
  }

  $async.Future<$0.ApplyResponse> apply(
      $grpc.ServiceCall call, $0.ApplyRequest request);
}
