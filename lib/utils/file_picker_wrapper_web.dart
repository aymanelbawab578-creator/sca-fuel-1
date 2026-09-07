import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'file_picker_wrapper.dart';

Future<PickedFileResult?> pickExcelFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'xls'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  if (file.bytes != null) {
    return PickedFileResult(bytes: file.bytes, path: file.name);
  }

  return null;
}
