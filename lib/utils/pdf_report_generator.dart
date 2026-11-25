import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/class_session_model.dart';
import '../models/attendance_record_model.dart';

class PdfReportGenerator {
  static Future<void> generateAndShareReport({
    required ClassSessionModel session,
    required List<AttendanceRecordModel> records,
    String institutionName = 'MOSHI COOPERATIVE UNIVERSITY (MoCU)',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Powered by Unilink • Intelligent Campus Attendance Platform (Page ${context.pageNumber} of ${context.pagesCount})',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(institutionName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    pw.Text('Official Academic Attendance & Exam Eligibility Report', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo900,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text('unilink', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1.5, color: PdfColors.indigo900),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Course Code: ${session.courseCode}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text('Lecturer: ${session.lecturerName}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Session ID: ${session.id}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Generated: ${DateTime.now().toLocal().toString().substring(0, 19)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Attendance Records & Exam Eligibility Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['No.', 'Student Name', 'Registration Number', 'Exact Timestamp', 'Status'],
              data: List.generate(records.length, (index) {
                final r = records[index];
                return [
                  '${index + 1}',
                  r.studentName.isNotEmpty ? r.studentName : 'Student',
                  r.registrationNumber.isNotEmpty ? r.registrationNumber : 'MoCU/REG/${r.id.substring(0, 6)}',
                  r.scannedAt?.toLocal().toString().substring(0, 19) ?? r.created?.toLocal().toString().substring(0, 19) ?? 'N/A',
                  'Present (Eligible)',
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Present: ${records.length} students', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Authorized Signature: ______________________', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Attendance_${session.courseCode}.pdf');
  }
}
