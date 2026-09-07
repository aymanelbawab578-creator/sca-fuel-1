import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sca_fuel/helpers/report_pdf_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildReportPdfBytes generates a PDF for Arabic reports with many rows', () async {
    final fontData = (await rootBundle.load('assets/fonts/arial.ttf')).buffer.asUint8List();
    final headers = [
      'رقم السيارة',
      'الأحرف',
      'النوع',
      'جهة التموين',
      'العداد',
      'اللترات',
      'النسبة',
      'الحالة',
    ];

    final rows = List<List<dynamic>>.generate(120, (index) {
      return [
        '123$index',
        'أ ب',
        '92',
        'محطة 1',
        '${1000 + index}',
        '${30 + index}',
        '${90 + index}',
        'مقبول',
      ];
    });

    final bytes = await buildReportPdfBytes(
      headers: headers,
      rows: rows,
      title: 'تقرير اختبار',
      fontData: fontData,
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });
}
