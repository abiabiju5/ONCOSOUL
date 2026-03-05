import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import '../services/cloudinary_service.dart';
import '../services/url_launcher_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MedicalReportsPage  —  list patients derived from the medical_reports
// collection, then drill into each patient's reports.
//
// FIX: Previously used patientsStream() which returns only patients who have
// appointments with this doctor. That caused an empty list when a patient had
// reports but no appointments. Now we derive the patient list directly from
// allReportsStream() — any patient who has at least one report appears here.
// ─────────────────────────────────────────────────────────────────────────────

class MedicalReportsPage extends StatefulWidget {
  const MedicalReportsPage({super.key});

  @override
  State<MedicalReportsPage> createState() => _MedicalReportsPageState();
}

class _MedicalReportsPageState extends State<MedicalReportsPage> {
  final _service = DoctorService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const Color _deepBlue  = Color(0xFF0D47A1);
  static const Color _skyBlue   = Color(0xFF1E88E5);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _surface   = Color(0xFFF0F4FF);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Build a deduplicated, sorted patient list from all reports.
  /// Each entry is a {userId, name, reportCount} map.
  List<_PatientSummary> _buildPatientList(List<FirestoreReport> reports) {
    final map = <String, _PatientSummary>{};
    for (final r in reports) {
      if (r.patientId.isEmpty) continue;
      map.update(
        r.patientId,
        (existing) => _PatientSummary(
          userId: existing.userId,
          name: existing.name,
          reportCount: existing.reportCount + 1,
          latestDate: r.uploadedAt.isAfter(existing.latestDate)
              ? r.uploadedAt
              : existing.latestDate,
        ),
        ifAbsent: () => _PatientSummary(
          userId: r.patientId,
          name: r.patientName.isNotEmpty ? r.patientName : r.patientId,
          reportCount: 1,
          latestDate: r.uploadedAt,
        ),
      );
    }
    final list = map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_deepBlue, _skyBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Medical Reports',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search patient by name or ID…',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _deepBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: _deepBlue.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _deepBlue, width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ── Patient list derived from reports ───────────────────────
          Expanded(
            child: StreamBuilder<List<FirestoreReport>>(
              stream: _service.allReportsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _deepBlue));
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: Colors.red)));
                }

                var patients = _buildPatientList(snap.data ?? []);

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  patients = patients
                      .where((p) =>
                          p.name.toLowerCase().contains(q) ||
                          p.userId.toLowerCase().contains(q))
                      .toList();
                }

                if (patients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                              color: _lightBlue, shape: BoxShape.circle),
                          child: const Icon(Icons.folder_open_rounded,
                              size: 40, color: _deepBlue),
                        ),
                        const SizedBox(height: 16),
                        const Text('No reports uploaded yet.',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(
                          'Upload a report from the Medical Staff dashboard.',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: patients.length,
                  itemBuilder: (context, i) {
                    final p = patients[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _deepBlue.withValues(alpha: 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _PatientReportsPage(
                              patientId: p.userId,
                              patientName: p.name,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Colour accent bar
                            Container(
                              width: 5,
                              height: 72,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_deepBlue, _skyBlue],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(16)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: _lightBlue,
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _deepBlue,
                                    fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Color(0xFF0D1B3E))),
                                    const SizedBox(height: 3),
                                    Text(
                                      'ID: ${p.userId}  ·  ${p.reportCount} report${p.reportCount == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(right: 14),
                              child: Icon(Icons.chevron_right_rounded,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple model for the patient list on this screen
// ─────────────────────────────────────────────────────────────────────────────

class _PatientSummary {
  final String userId;
  final String name;
  final int reportCount;
  final DateTime latestDate;

  const _PatientSummary({
    required this.userId,
    required this.name,
    required this.reportCount,
    required this.latestDate,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// _PatientReportsPage  —  report list for one patient
// ─────────────────────────────────────────────────────────────────────────────

class _PatientReportsPage extends StatelessWidget {
  final String patientId;
  final String patientName;
  const _PatientReportsPage({
    required this.patientId,
    required this.patientName,
  });

  static const Color _deepBlue  = Color(0xFF0D47A1);
  static const Color _skyBlue   = Color(0xFF1E88E5);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _surface   = Color(0xFFF0F4FF);

  /// Routes PDF files through Google Docs Viewer so they render in-browser
  /// without requiring Content-Disposition: inline (blocked by unsigned preset).
  static String _fixCloudinaryUrl(String url) =>
      CloudinaryService.prepareViewUrl(url);

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lab report':   return const Color(0xFF1565C0);
      case 'imaging':      return const Color(0xFF00695C);
      case 'pathology':    return const Color(0xFF6A1B9A);
      case 'prescription': return const Color(0xFFE65100);
      default:             return _deepBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = DoctorService();
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_deepBlue, _skyBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text("$patientName's Reports",
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<FirestoreReport>>(
        stream: service.reportsForPatient(patientId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _deepBlue));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final reports = snap.data ?? [];
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        color: _lightBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.description_outlined,
                        size: 40, color: _deepBlue),
                  ),
                  const SizedBox(height: 16),
                  const Text('No reports uploaded yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final r = reports[i];
              final color = _typeColor(r.reportType);
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _deepBlue.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 4, color: color),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header ───────────────────────────────────
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.description_rounded,
                                    size: 22, color: color),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.reportType,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0D1B3E))),
                                    const SizedBox(height: 2),
                                    if (r.labName.isNotEmpty)
                                      Text(r.labName,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(r.reportType,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                              ),
                            ]),

                            const SizedBox(height: 14),
                            Divider(height: 1, color: Colors.grey.shade100),
                            const SizedBox(height: 12),

                            // ── Meta ────────────────────────────────────
                            Row(children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text(
                                '${r.uploadedAt.day}/${r.uploadedAt.month}/${r.uploadedAt.year}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.person_outline_rounded,
                                  size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('By ${r.uploadedBy}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),

                            // ── Notes ───────────────────────────────────
                            if (r.notes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.notes_rounded,
                                        size: 14,
                                        color: Colors.grey.shade500),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(r.notes,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                              height: 1.5)),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // ── View File ────────────────────────────────
                            if (r.fileUrl != null &&
                                r.fileUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final viewUrl =
                                        _fixCloudinaryUrl(r.fileUrl!);
                                    try {
                                      await openFileUrl(
                                        context,
                                        viewUrl,
                                        title: r.reportType,
                                      );
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text('Could not open file.'),
                                          duration: Duration(seconds: 3),
                                        ));
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.picture_as_pdf_rounded,
                                      size: 16),
                                  label: const Text('View Report'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _deepBlue,
                                    side: const BorderSide(color: _deepBlue),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}