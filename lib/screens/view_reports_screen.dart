import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/patient_service.dart';

class ViewReportsScreen extends StatelessWidget {
  const ViewReportsScreen({super.key});

  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color softBlue = Color(0xFFE3F2FD);
  static const Color bgColor = Color(0xFFF0F4FC);

  @override
  Widget build(BuildContext context) {
    final service = PatientService();
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<PatientReport>>(
        stream: service.myReportsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)));
          }
          final reports = snap.data ?? [];
          if (reports.isEmpty) return _buildEmpty();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: reports.length,
            itemBuilder: (_, i) => _ReportCard(report: reports[i]),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: deepBlue),
        ),
      ),
      centerTitle: true,
      title: const Text('My Reports',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: deepBlue, letterSpacing: -0.3)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE8EEF8)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(color: softBlue, shape: BoxShape.circle),
          child: const Icon(Icons.description_outlined, size: 38, color: deepBlue),
        ),
        const SizedBox(height: 20),
        const Text('No Reports Yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E))),
        const SizedBox(height: 8),
        Text('Your medical reports will appear here once uploaded.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final PatientReport report;
  const _ReportCard({required this.report});

  static const Color deepBlue = Color(0xFF0D47A1);

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lab report': return const Color(0xFF1565C0);
      case 'imaging': return const Color(0xFF00695C);
      case 'pathology': return const Color(0xFF6A1B9A);
      case 'prescription': return const Color(0xFFE65100);
      default: return deepBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(report.reportType);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 4, color: color),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.description_rounded, size: 22, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(report.reportType,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E))),
                  const SizedBox(height: 3),
                  Text(report.labName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                  child: Text(report.reportType,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                ),
              ]),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(_formatDate(report.uploadedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(width: 16),
                Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(child: Text('By ${report.uploadedBy}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis)),
              ]),
              if (report.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4FC), borderRadius: BorderRadius.circular(8)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.notes_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Expanded(child: Text(report.notes,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5))),
                  ]),
                ),
              ],
              if (report.fileUrl != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(report.fileUrl!);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open file.')));
                        }
                      }
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View File'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: deepBlue,
                      side: const BorderSide(color: deepBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}