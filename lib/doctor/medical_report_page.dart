import 'package:flutter/material.dart';
import '../services/doctor_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MedicalReportsPage  —  browse all patients then drill into their reports
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
                          child: const Icon(Icons.folder_open_rounded,
                              size: 40, color: _deepBlue),
                        ),
                        const SizedBox(height: 16),
                        const Text('No patients found.',
                            style: TextStyle(color: Colors.grey, fontSize: 15)),
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
                            builder: (_) =>
                                _PatientReportsPage(patient: p),
                          ),
                        ),
                        child: Row(
                          children: [
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
                                            fontSize: 12,
                                            color: Colors.grey)),
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
// _PatientReportsPage  —  report list for one patient
// ─────────────────────────────────────────────────────────────────────────────

class _PatientReportsPage extends StatelessWidget {
  final DoctorPatient patient;
  const _PatientReportsPage({required this.patient});

  static const Color _deepBlue  = Color(0xFF0D47A1);
  static const Color _skyBlue   = Color(0xFF1E88E5);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _surface   = Color(0xFFF0F4FF);

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
        title: Text("${patient.name}'s Reports",
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<FirestoreReport>>(
        stream: service.reportsForPatient(patient.userId),
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
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left bar
                    Container(
                      width: 5,
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _lightBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.insert_drive_file_rounded,
                                      color: _deepBlue,
                                      size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.reportType,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Color(0xFF0D1B3E))),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Uploaded: ${r.uploadedAt.day}/${r.uploadedAt.month}/${r.uploadedAt.year}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (r.notes.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Notes',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                            color: _deepBlue)),
                                    const SizedBox(height: 4),
                                    Text(r.notes,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF0D1B3E))),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text('Uploaded by: ${r.uploadedBy}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}