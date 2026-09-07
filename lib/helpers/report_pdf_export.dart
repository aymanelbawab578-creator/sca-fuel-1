import 'dart:typed_data';

import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildReportPdfBytes({
  required List<String> headers,
  required List<List<dynamic>> rows,
  required String title,
  required Uint8List fontData,
  bool landscape = false,
  Map<int, pw.TableColumnWidth>? columnWidths,
}) async {
  late final pw.Font baseFont;
  try {
    final byteData = fontData.buffer.asByteData();
    baseFont = pw.Font.ttf(byteData);
  } catch (_) {
    baseFont = pw.Font.helvetica();
  }

  final pdfDoc = pw.Document();
  final normalizedRows = rows
      .map((row) => row.map((value) => _normalizeCellValue(value)).toList())
      .toList();
  final normalizedHeaders = headers
      .map((value) => _normalizeCellValue(value))
      .toList();

  const maxRowsPerPage = 18;
  final chunkedRows = <List<List<dynamic>>>[];
  for (var i = 0; i < normalizedRows.length; i += maxRowsPerPage) {
    final end = (i + maxRowsPerPage < normalizedRows.length)
        ? i + maxRowsPerPage
        : normalizedRows.length;
    chunkedRows.add(normalizedRows.sublist(i, end));
  }

  for (final chunk in chunkedRows) {
    pdfDoc.addPage(
      pw.Page(
        pageFormat: landscape
            ? pdf.PdfPageFormat.a4.landscape
            : pdf.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: normalizedHeaders,
                  data: chunk,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(
                    font: baseFont,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: pw.TextStyle(font: baseFont, fontSize: 7),
                  cellAlignment: pw.Alignment.centerRight,
                  headerDecoration: const pw.BoxDecoration(
                    color: pdf.PdfColors.grey300,
                  ),
                  tableWidth: pw.TableWidth.max,
                  columnWidths: columnWidths,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  return await pdfDoc.save();
}

String _normalizeCellValue(dynamic value) {
  if (value == null) return '';
  if (value is num || value is bool) return value.toString();
  if (value is DateTime) return value.toLocal().toIso8601String();
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '' : trimmed;
  }
  return value.toString();
}
