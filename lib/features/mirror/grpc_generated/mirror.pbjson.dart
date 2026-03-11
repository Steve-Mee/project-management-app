// This is a generated file - do not edit.
//
// Generated from mirror.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use compileRequestDescriptor instead')
const CompileRequest$json = {
  '1': 'CompileRequest',
  '2': [
    {'1': 'prompt', '3': 1, '4': 1, '5': 9, '10': 'prompt'},
    {'1': 'project_id', '3': 2, '4': 1, '5': 9, '10': 'projectId'},
    {'1': 'task_id', '3': 3, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'mode', '3': 4, '4': 1, '5': 9, '10': 'mode'},
    {
      '1': 'files',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.mirror.compute.v1.CompileRequest.FilesEntry',
      '10': 'files'
    },
    {'1': 'metadata_json', '3': 6, '4': 1, '5': 9, '10': 'metadataJson'},
  ],
  '3': [CompileRequest_FilesEntry$json],
};

@$core.Deprecated('Use compileRequestDescriptor instead')
const CompileRequest_FilesEntry$json = {
  '1': 'FilesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `CompileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compileRequestDescriptor = $convert.base64Decode(
    'Cg5Db21waWxlUmVxdWVzdBIWCgZwcm9tcHQYASABKAlSBnByb21wdBIdCgpwcm9qZWN0X2lkGA'
    'IgASgJUglwcm9qZWN0SWQSFwoHdGFza19pZBgDIAEoCVIGdGFza0lkEhIKBG1vZGUYBCABKAlS'
    'BG1vZGUSQgoFZmlsZXMYBSADKAsyLC5taXJyb3IuY29tcHV0ZS52MS5Db21waWxlUmVxdWVzdC'
    '5GaWxlc0VudHJ5UgVmaWxlcxIjCg1tZXRhZGF0YV9qc29uGAYgASgJUgxtZXRhZGF0YUpzb24a'
    'OAoKRmlsZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6Aj'
    'gB');

@$core.Deprecated('Use compileResponseDescriptor instead')
const CompileResponse$json = {
  '1': 'CompileResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'output', '3': 2, '4': 1, '5': 9, '10': 'output'},
    {'1': 'errors', '3': 3, '4': 3, '5': 9, '10': 'errors'},
    {'1': 'warnings', '3': 4, '4': 3, '5': 9, '10': 'warnings'},
    {'1': 'logs', '3': 5, '4': 3, '5': 9, '10': 'logs'},
    {'1': 'signed_url', '3': 6, '4': 1, '5': 9, '10': 'signedUrl'},
    {'1': 'artifact_path', '3': 7, '4': 1, '5': 9, '10': 'artifactPath'},
    {'1': 'error_json', '3': 8, '4': 1, '5': 9, '10': 'errorJson'},
  ],
};

/// Descriptor for `CompileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compileResponseDescriptor = $convert.base64Decode(
    'Cg9Db21waWxlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIWCgZvdXRwdXQYAi'
    'ABKAlSBm91dHB1dBIWCgZlcnJvcnMYAyADKAlSBmVycm9ycxIaCgh3YXJuaW5ncxgEIAMoCVII'
    'd2FybmluZ3MSEgoEbG9ncxgFIAMoCVIEbG9ncxIdCgpzaWduZWRfdXJsGAYgASgJUglzaWduZW'
    'RVcmwSIwoNYXJ0aWZhY3RfcGF0aBgHIAEoCVIMYXJ0aWZhY3RQYXRoEh0KCmVycm9yX2pzb24Y'
    'CCABKAlSCWVycm9ySnNvbg==');

@$core.Deprecated('Use applyRequestDescriptor instead')
const ApplyRequest$json = {
  '1': 'ApplyRequest',
  '2': [
    {'1': 'prompt', '3': 1, '4': 1, '5': 9, '10': 'prompt'},
    {'1': 'project_id', '3': 2, '4': 1, '5': 9, '10': 'projectId'},
    {'1': 'task_id', '3': 3, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'mode', '3': 4, '4': 1, '5': 9, '10': 'mode'},
    {
      '1': 'files',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.mirror.compute.v1.ApplyRequest.FilesEntry',
      '10': 'files'
    },
    {'1': 'metadata_json', '3': 6, '4': 1, '5': 9, '10': 'metadataJson'},
  ],
  '3': [ApplyRequest_FilesEntry$json],
};

@$core.Deprecated('Use applyRequestDescriptor instead')
const ApplyRequest_FilesEntry$json = {
  '1': 'FilesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ApplyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyRequestDescriptor = $convert.base64Decode(
    'CgxBcHBseVJlcXVlc3QSFgoGcHJvbXB0GAEgASgJUgZwcm9tcHQSHQoKcHJvamVjdF9pZBgCIA'
    'EoCVIJcHJvamVjdElkEhcKB3Rhc2tfaWQYAyABKAlSBnRhc2tJZBISCgRtb2RlGAQgASgJUgRt'
    'b2RlEkAKBWZpbGVzGAUgAygLMioubWlycm9yLmNvbXB1dGUudjEuQXBwbHlSZXF1ZXN0LkZpbG'
    'VzRW50cnlSBWZpbGVzEiMKDW1ldGFkYXRhX2pzb24YBiABKAlSDG1ldGFkYXRhSnNvbho4CgpG'
    'aWxlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use applyResponseDescriptor instead')
const ApplyResponse$json = {
  '1': 'ApplyResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'output', '3': 2, '4': 1, '5': 9, '10': 'output'},
    {'1': 'errors', '3': 3, '4': 3, '5': 9, '10': 'errors'},
    {'1': 'warnings', '3': 4, '4': 3, '5': 9, '10': 'warnings'},
    {'1': 'logs', '3': 5, '4': 3, '5': 9, '10': 'logs'},
    {'1': 'signed_url', '3': 6, '4': 1, '5': 9, '10': 'signedUrl'},
    {'1': 'artifact_path', '3': 7, '4': 1, '5': 9, '10': 'artifactPath'},
    {'1': 'error_json', '3': 8, '4': 1, '5': 9, '10': 'errorJson'},
  ],
};

/// Descriptor for `ApplyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyResponseDescriptor = $convert.base64Decode(
    'Cg1BcHBseVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSFgoGb3V0cHV0GAIgAS'
    'gJUgZvdXRwdXQSFgoGZXJyb3JzGAMgAygJUgZlcnJvcnMSGgoId2FybmluZ3MYBCADKAlSCHdh'
    'cm5pbmdzEhIKBGxvZ3MYBSADKAlSBGxvZ3MSHQoKc2lnbmVkX3VybBgGIAEoCVIJc2lnbmVkVX'
    'JsEiMKDWFydGlmYWN0X3BhdGgYByABKAlSDGFydGlmYWN0UGF0aBIdCgplcnJvcl9qc29uGAgg'
    'ASgJUgllcnJvckpzb24=');
