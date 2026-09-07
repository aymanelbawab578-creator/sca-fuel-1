import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> saveBytesAsFile(String filename, Uint8List bytes) async {
  final savePath = await FilePicker.platform.saveFile(
    dialogTitle: 'اختر مكان حفظ الملف',
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'xls', 'pdf'],
  );

  if (savePath == null) {
    throw Exception('تم إلغاء حفظ الملف');
  }

  final outputFile = File(savePath);
  await outputFile.writeAsBytes(bytes);
}
