import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../models/report_model.dart';

class MedicalReportDetailsPage extends StatelessWidget {
  final ReportModel report;

  const MedicalReportDetailsPage({
    super.key,
    required this.report,
  });

  bool isImage(String path) {
    return path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.png') ||
        path.toLowerCase().endsWith('.jpeg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text("Date: ${report.date}"),
                const SizedBox(height: 20),

                // ✅ If image → show preview
                if (report.path != null &&
                    report.path!.isNotEmpty &&
                    isImage(report.path!))
                  Expanded(
                    child: Image.file(
                      File(report.path!),
                      fit: BoxFit.contain,
                    ),
                  )

                // ✅ If PDF → show open button
                else if (report.path != null &&
                    report.path!.isNotEmpty)
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Open PDF Report"),
                      onPressed: () {
                        OpenFile.open(report.path!);
                      },
                    ),
                  )

                else
                  const Text(
                    "Detailed report information will appear here.",
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
