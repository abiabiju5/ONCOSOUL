import 'package:flutter/material.dart';
import '../services/doctor_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PatientsPage  —  list of all patients
// ─────────────────────────────────────────────────────────────────────────────

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
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
        title: const Text('My Patients',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search patient…',
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

          // Patient list
          Expanded(
            child: StreamBuilder<List<DoctorPatient>>(
              stream: _service.patientsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _deepBlue));
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                var patients = snap.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  patients = patients
                      .where((p) => p.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
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
                          child: const Icon(Icons.people_outline_rounded,
                              size: 40, color: _deepBlue),
                        ),
                        const SizedBox(height: 16),
                        const Text('No patients found.',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                                fontWeight: FontWeight.w500)),
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
                            builder: (_) => PatientDetailsPage(patient: p),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Left bar
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
                                    Text('ID: ${p.userId}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
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
// PatientDetailsPage  —  full profile with reports & summaries
// ─────────────────────────────────────────────────────────────────────────────

class PatientDetailsPage extends StatelessWidget {
  final DoctorPatient patient;
  const PatientDetailsPage({super.key, required this.patient});

  static const Color _deepBlue   = Color(0xFF0D47A1);
  static const Color _skyBlue    = Color(0xFF1E88E5);
  static const Color _lightBlue  = Color(0xFFE3F2FD);
  static const Color _surface    = Color(0xFFF0F4FF);
  static const Color _textPrim   = Color(0xFF0D1B3E);
  static const Color _textSec    = Color(0xFF6B7280);

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
        title: Text(patient.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile card ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _deepBlue.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar with gradient ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [_deepBlue, _skyBlue]),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: _lightBlue,
                      child: Text(
                        patient.name.isNotEmpty
                            ? patient.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _deepBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textPrim)),
                        const SizedBox(height: 4),
                        Text('Patient ID: ${patient.userId}',
                            style: const TextStyle(
                                color: _textSec, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: patient.isActive
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: patient.isActive
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Text(
                            patient.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: patient.isActive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Medical Reports ───────────────────────────────────────────
            _sectionHeader('Medical Reports', Icons.description_rounded),
            const SizedBox(height: 10),
            StreamBuilder<List<FirestoreReport>>(
              stream: service.reportsForPatient(patient.userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _deepBlue));
                }
                final reports = snap.data ?? [];
                if (reports.isEmpty) {
                  return _emptyCard(
                      Icons.folder_open_rounded, 'No reports uploaded yet.');
                }
                return Column(
                  children: reports
                      .map((r) => _reportTile(r))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Offline Visit Summaries ────────────────────────────────────
            _sectionHeader(
                'Offline Visit Summaries', Icons.history_rounded),
            const SizedBox(height: 10),
            StreamBuilder<List<FirestoreSummary>>(
              stream: service.summariesForPatient(patient.userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _deepBlue));
                }
                final summaries = snap.data ?? [];
                if (summaries.isEmpty) {
                  return _emptyCard(
                      Icons.history_rounded, 'No summaries found.');
                }
                return Column(
                  children: summaries
                      .map((s) => _summaryTile(s))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_deepBlue, _skyBlue]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrim)),
    ]);
  }

  Widget _emptyCard(IconData icon, String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: _deepBlue.withValues(alpha: 0.5), size: 22),
        const SizedBox(width: 10),
        Text(msg,
            style: const TextStyle(color: _textSec, fontSize: 13)),
      ]),
    );
  }

  Widget _reportTile(FirestoreReport r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                color: _deepBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.reportType,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _textPrim)),
                const SizedBox(height: 2),
                Text(
                  '${r.uploadedAt.day}/${r.uploadedAt.month}/${r.uploadedAt.year}  •  ${r.uploadedBy}',
                  style:
                      const TextStyle(fontSize: 11, color: _textSec),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(FirestoreSummary s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_hospital_rounded,
                color: _deepBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.diagnosis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _textPrim)),
                const SizedBox(height: 2),
                Text(
                  '${s.uploadedAt.day}/${s.uploadedAt.month}/${s.uploadedAt.year}  •  ${s.doctorName}',
                  style:
                      const TextStyle(fontSize: 11, color: _textSec),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}