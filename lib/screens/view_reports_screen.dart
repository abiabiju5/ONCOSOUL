import 'package:flutter/material.dart';

class ViewReportsScreen extends StatelessWidget {
  const ViewReportsScreen({super.key});
final Color deepBlue = const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Medical Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          reportCard(
            context,
            reportName: 'Blood Test Report',
            hospital: 'City Cancer Hospital',
            date: '10 Oct 2026',
            type: 'Lab Report',
          ),
          reportCard(
            context,
            reportName: 'CT Scan Result',
            hospital: 'Apollo Oncology',
            date: '28 Sep 2026',
            type: 'Imaging',
          ),
          reportCard(
            context,
            reportName: 'Biopsy Analysis',
            hospital: 'Regional Medical Center',
            date: '15 Sep 2026',
            type: 'Pathology',
          ),
        ],
      ),
    );
  }

  // 🔹 SINGLE REPORT CARD
  Widget reportCard(
    BuildContext context, {
    required String reportName,
    required String hospital,
    required String date,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: deepBlue.withValues(alpha:0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reportName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: deepBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hospital,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: deepBlue),
              const SizedBox(width: 6),
              Text(date),
              const SizedBox(width: 16),
              Icon(Icons.folder_open_outlined,
                  size: 16, color: deepBlue),
              const SizedBox(width: 6),
              Text(type),
            ],
          ),
          const SizedBox(height: 16),

          // ACTION BUTTON (VIEW ONLY)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('View report (UI only)'),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined,
                  color: Colors.white),
              label: const Text(
                'View',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: deepBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}