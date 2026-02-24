import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ── PrescriptionPdfService ────────────────────────────────────────────────────
//
// Add to pubspec.yaml:
//   pdf: ^3.10.8
//   printing: ^5.12.0
//   path_provider: ^2.1.2
//
// No intl dependency needed — date is formatted manually.

class PrescriptionPdfService {
  PrescriptionPdfService._();

  static const PdfColor _green = PdfColor.fromInt(0xFF1B8A5A);
  static const PdfColor _lightGreen = PdfColor.fromInt(0xFFE8F5EE);
  static const PdfColor _grey = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1A1A2E);

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Format a DateTime as "dd MMM yyyy" without the intl package.
  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Generates a prescription PDF and returns the [File].
  static Future<File> generatePrescriptionPdf({
    required String patientName,
    required String doctorName,
    required List<Map<String, String>> medicines,
    String? patientId,
    String? clinicName,
    String? clinicAddress,
    String? clinicPhone,
    DateTime? prescriptionDate,
  }) async {
    final pdf = pw.Document();
    final date = prescriptionDate ?? DateTime.now();
    final dateStr = _formatDate(date);
    final clinic = clinicName ?? 'OncaSoul Cancer Care';
    final address = clinicAddress ?? 'Specialist Oncology Clinic';
    final phone = clinicPhone ?? '';

    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      // No logo asset — skip gracefully
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(clinic, address, phone, doctorName, logo),
            pw.SizedBox(height: 16),
            _divider(),
            pw.SizedBox(height: 12),
            _patientRow(patientName, patientId, dateStr),
            pw.SizedBox(height: 20),
            _rxHeading(),
            pw.SizedBox(height: 10),
            _medicineTable(medicines),
            pw.SizedBox(height: 24),
            _footer(doctorName),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName =
        'prescription_${patientName.replaceAll(' ', '_')}_${date.millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Opens the system print / share dialog for [file].
  static Future<void> printPdf(File file) async {
    await Printing.layoutPdf(
      onLayout: (_) async => file.readAsBytes(),
    );
  }

  /// Share sheet so the user can send/save the PDF.
  static Future<void> sharePdf(File file) async {
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: file.path.split('/').last,
    );
  }

  // ── Private builders ──────────────────────────────────────────────────────────

  static pw.Widget _header(
    String clinic,
    String address,
    String phone,
    String doctorName,
    pw.MemoryImage? logo,
  ) {
    return pw.Container(
      color: _lightGreen,
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null) ...[
            pw.Image(logo, width: 52, height: 52),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  clinic,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _green,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(address,
                    style: pw.TextStyle(fontSize: 11, color: _grey)),
                if (phone.isNotEmpty)
                  pw.Text('Tel: $phone',
                      style: pw.TextStyle(fontSize: 11, color: _grey)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                doctorName,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark,
                ),
              ),
              pw.Text('Oncologist',
                  style: pw.TextStyle(fontSize: 11, color: _grey)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _divider() => pw.Divider(color: _green, thickness: 1.5);

  static pw.Widget _patientRow(
      String patientName, String? patientId, String dateStr) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Patient',
                style: pw.TextStyle(fontSize: 10, color: _grey)),
            pw.Text(
              patientName,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark),
            ),
            if (patientId != null)
              pw.Text('ID: $patientId',
                  style: pw.TextStyle(fontSize: 10, color: _grey)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Date',
                style: pw.TextStyle(fontSize: 10, color: _grey)),
            pw.Text(dateStr,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _rxHeading() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const pw.BoxDecoration(color: _green),
      child: pw.Text(
        'Rx  —  Prescription',
        style: pw.TextStyle(
            fontSize: 13,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _medicineTable(List<Map<String, String>> medicines) {
    const headers = ['Medicine', 'Dosage', 'Duration', 'Instructions'];
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: medicines
          .map((m) => [
                m['medicine'] ?? '',
                m['dosage'] ?? '',
                m['duration'] ?? '',
                m['instructions'] ?? '',
              ])
          .toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 11,
      ),
      headerDecoration: const pw.BoxDecoration(color: _green),
      cellStyle: pw.TextStyle(fontSize: 11, color: _textDark),
      rowDecoration: const pw.BoxDecoration(color: _lightGreen),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      border: pw.TableBorder.all(color: _green, width: 0.5),
      cellPadding:
          const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(3),
      },
    );
  }

  static pw.Widget _footer(String doctorName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Divider(color: _grey, thickness: 0.5),
        pw.SizedBox(height: 40),
        pw.Text('_______________________',
            style: pw.TextStyle(color: _grey)),
        pw.Text(doctorName,
            style:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Text("Doctor's Signature",
            style: pw.TextStyle(fontSize: 10, color: _grey)),
        pw.SizedBox(height: 12),
        pw.Text(
          'This prescription is valid for 30 days from the date of issue.',
          style: pw.TextStyle(fontSize: 9, color: _grey),
        ),
      ],
    );
  }
}