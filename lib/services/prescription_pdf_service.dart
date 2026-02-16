import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrescriptionPdfService {
  static Future<File> generatePrescriptionPdf({
    required String patientName,
    required String doctorName,
    required List<Map<String, String>> medicines,
  }) async {
    final pdf = pw.Document();

    // Load signature image
    final signatureImage =
        pw.MemoryImage((await rootBundle.load('assets/images/signature.png'))
            .buffer
            .asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Medical Prescription',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Patient Info
              pw.Text('Patient Name: $patientName'),
              pw.Text(
                  'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              pw.SizedBox(height: 20),

              // Medicine Table
              pw.TableHelper.fromTextArray(
                headers: ['Medicine', 'Dosage', 'Duration'],
                data: medicines
                    .map((med) => [
                          med['medicine'], // ✅ FIXED HERE
                          med['dosage'],
                          med['duration'],
                        ])
                    .toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    pw.BoxDecoration(color: PdfColors.grey300),
              ),

              pw.SizedBox(height: 40),

              pw.Text('Doctor Signature:'),
              pw.SizedBox(height: 10),
              pw.Image(signatureImage, height: 60),

              pw.SizedBox(height: 10),
              pw.Text(
                doctorName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/prescription.pdf");
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static Future<void> printPdf(File file) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => file.readAsBytes(),
    );
  }
}
