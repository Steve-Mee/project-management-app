import 'dart:io';
import 'dart:typed_data';

/// Gzip-compresses [input]. Returns `null` if compression fails.
Uint8List? tryGzip(List<int> input) {
  try {
    return Uint8List.fromList(GZipCodec().encode(input));
  } catch (_) {
    return null;
  }
}
