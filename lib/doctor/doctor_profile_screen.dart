import 'package:flutter/material.dart';
import '../models/app_user_session.dart';
import '../services/doctor_service.dart';
import '../login.dart';

// ── DoctorProfileScreen ───────────────────────────────────────────────────────

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _service = DoctorService();

  final _phoneCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  bool _isSaving = false;

  static const Color _blue = Color(0xFF0D47A1);
  static const Color _lightBlue = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    final doctor = AppUserSession.currentUser;
    _phoneCtrl.text = doctor?.phone ?? '';
    _specialtyCtrl.text = doctor?.specialty ?? '';
  }

  @override
  void dispose() {
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
          backgroundColor: Color(0xFF0D47A1),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'You will need to sign in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF0D47A1))),
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
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: _blue,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar + name ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: _lightBlue,
                    backgroundImage: doctor?.profileUrl != null
                        ? NetworkImage(doctor!.profileUrl!)
                        : null,
                    child: doctor?.profileUrl == null
                        ? Text(initials,
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _blue))
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
                      color: _lightBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      doctor?.specialty?.isNotEmpty == true
                          ? doctor!.specialty!
                          : 'Oncologist',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _blue),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Read-only info card ────────────────────────────────────
            _infoCard([
              _infoRow(Icons.badge_outlined, 'Doctor ID',
                  doctor?.userId ?? '—'),
              _infoRow(Icons.email_outlined, 'Email',
                  doctor?.email.isNotEmpty == true ? doctor!.email : '—'),
              _infoRow(
                Icons.circle,
                'Status',
                doctor?.isActive == true ? 'Active' : 'Inactive',
                valueColor:
                    doctor?.isActive == true ? Colors.green : Colors.red,
              ),
            ]),

            const SizedBox(height: 16),

            // ── Editable fields ────────────────────────────────────────
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
                  const Text('Edit Details',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _blue)),
                  const SizedBox(height: 12),
                  _editField(
                    ctrl: _specialtyCtrl,
                    label: 'Specialty',
                    icon: Icons.medical_services_outlined,
                    hint: 'e.g. Oncologist, Surgeon',
                  ),
                  const SizedBox(height: 12),
                  _editField(
                    ctrl: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    hint: 'e.g. +91 98765 43210',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_isSaving ? 'Saving…' : 'Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
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
            borderSide:
                const BorderSide(color: Color(0xFF0D47A1), width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 13),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}