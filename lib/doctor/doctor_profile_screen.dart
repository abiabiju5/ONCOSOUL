import 'package:flutter/material.dart';
import '../models/app_user_session.dart';
import '../services/doctor_service.dart';
import '../login.dart';

// ── DoctorProfileScreen ───────────────────────────────────────────────────────
// Lets the doctor view their profile details and update phone/specialty.
// Also shows a tab for prescription history they've issued.

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _service = DoctorService();

  // Edit controllers
  final _phoneCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  bool _isSaving = false;

  static const Color _green = Color(0xFF1B8A5A);
  static const Color _lightGreen = Color(0xFFE8F5EE);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final doctor = AppUserSession.currentUser;
    _phoneCtrl.text = doctor?.phone ?? '';
    _specialtyCtrl.text = doctor?.specialty ?? '';
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _phoneCtrl.dispose();
    _specialtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _service.updateDoctorProfile(
        phone: _phoneCtrl.text.trim(),
        specialty: _specialtyCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF1B8A5A),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'You will need to sign in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF1B8A5A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              AppUserSession.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = AppUserSession.currentUser;
    final initials = (doctor?.name.isNotEmpty == true)
        ? doctor!.name[0].toUpperCase()
        : 'D';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _confirmLogout,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Prescriptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ProfileTab(
            doctor: doctor,
            initials: initials,
            phoneCtrl: _phoneCtrl,
            specialtyCtrl: _specialtyCtrl,
            isSaving: _isSaving,
            onSave: _saveProfile,
            green: _green,
            lightGreen: _lightGreen,
          ),
          _PrescriptionHistoryTab(service: _service, green: _green),
        ],
      ),
    );
  }
}

// ── _ProfileTab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final AppUser? doctor;
  final String initials;
  final TextEditingController phoneCtrl;
  final TextEditingController specialtyCtrl;
  final bool isSaving;
  final VoidCallback onSave;
  final Color green;
  final Color lightGreen;

  const _ProfileTab({
    required this.doctor,
    required this.initials,
    required this.phoneCtrl,
    required this.specialtyCtrl,
    required this.isSaving,
    required this.onSave,
    required this.green,
    required this.lightGreen,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Avatar + name ──────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: lightGreen,
                  backgroundImage: doctor?.profileUrl != null
                      ? NetworkImage(doctor!.profileUrl!)
                      : null,
                  child: doctor?.profileUrl == null
                      ? Text(initials,
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: green))
                      : null,
                ),
                const SizedBox(height: 12),
                Text('Dr. ${doctor?.name ?? ''}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    doctor?.specialty?.isNotEmpty == true
                        ? doctor!.specialty!
                        : 'Oncologist',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: green),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Read-only info card ────────────────────────────────────────
          _infoCard([
            _infoRow(Icons.badge_outlined, 'Doctor ID',
                doctor?.userId ?? '—'),
            _infoRow(Icons.email_outlined, 'Email',
                doctor?.email.isNotEmpty == true
                    ? doctor!.email
                    : '—'),
            _infoRow(
              Icons.circle,
              'Status',
              doctor?.isActive == true ? 'Active' : 'Inactive',
              valueColor: doctor?.isActive == true
                  ? Colors.green
                  : Colors.red,
            ),
          ]),

          const SizedBox(height: 16),

          // ── Editable fields ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Details',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: green)),
                const SizedBox(height: 12),
                _editField(
                  ctrl: specialtyCtrl,
                  label: 'Specialty',
                  icon: Icons.medical_services_outlined,
                  hint: 'e.g. Oncologist, Surgeon',
                  green: green,
                ),
                const SizedBox(height: 12),
                _editField(
                  ctrl: phoneCtrl,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  hint: 'e.g. +91 98765 43210',
                  keyboardType: TextInputType.phone,
                  green: green,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(isSaving ? 'Saving…' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving ? null : onSave,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
          children: List.generate(rows.length, (i) {
        return Column(
          children: [
            rows[i],
            if (i < rows.length - 1)
              Divider(height: 16, color: Colors.grey.shade100),
          ],
        );
      })),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF1A1A2E))),
          ],
        ),
      ),
    ]);
  }

  Widget _editField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required String hint,
    required Color green,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: green, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 13),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}

// ── _PrescriptionHistoryTab ───────────────────────────────────────────────────

class _PrescriptionHistoryTab extends StatelessWidget {
  final DoctorService service;
  final Color green;

  const _PrescriptionHistoryTab(
      {required this.service, required this.green});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DoctorPrescription>>(
      stream: service.prescriptionsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final prescriptions = snap.data ?? [];
        if (prescriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medication_outlined,
                    size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('No prescriptions issued yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                  'Prescriptions you issue in the consultation room\nwill appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: prescriptions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final p = prescriptions[i];
            final dateStr =
                '${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}';
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medication_rounded,
                            color: Color(0xFF7B1FA2), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.patientName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            Text(
                              'Patient ID: ${p.patientId}  •  $dateStr',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    const Text('Medicines Prescribed',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...p.medicines.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(
                                  top: 1, right: 8),
                              decoration: const BoxDecoration(
                                  color: Color(0xFF7B1FA2),
                                  shape: BoxShape.circle),
                            ),
                            Expanded(
                              child: Text(
                                '${m['medicine'] ?? ''}'
                                '${m['dosage']?.isNotEmpty == true ? ' — ${m['dosage']}' : ''}'
                                '${m['duration']?.isNotEmpty == true ? ', ${m['duration']}' : ''}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ]),
                        )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}