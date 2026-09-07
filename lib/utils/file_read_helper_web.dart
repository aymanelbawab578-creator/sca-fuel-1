import 'dart:typed_data';

Future<Uint8List> readFileBytes(String path) async {
  throw UnsupportedError('Reading local filesystem paths is not supported on web.');
}
