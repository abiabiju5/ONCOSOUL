import 'package:flutter/material.dart';
import '../models/app_user_session.dart';
import '../services/patient_service.dart';
import '../login.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});
  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  static const Color blue = Color(0xFF1E5AA8);
  static const Color lightBlue = Color(0xFFDEECFB);
  static const Color bg = Color(0xFFF0F5FF);

  final _service = PatientService();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = AppUserSession.currentUser;
    _phoneCtrl.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: lightBlue, shape: BoxShape.circle),
          child: const Icon(Icons.logout_rounded, color: blue, size: 26)),
        const SizedBox(height: 16),
        const Text('Sign Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0B2E6B))),
        const SizedBox(height: 8),
        Text('Are you sure you want to sign out?', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5)),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.shade200, width: 1.5)),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13)),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              AppUserSession.clear();
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          )),
        ]),
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = AppUserSession.currentUser;
    final initials = user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: blue, foregroundColor: Colors.white, elevation: 0,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _confirmLogout, tooltip: 'Sign Out'),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _service.myProfileStream(),
        builder: (context, snap) {
          final data = snap.data ?? {};
          if (true) {
            _phoneCtrl.text = data['phone'] ?? user?.phone ?? '';
            _addressCtrl.text = data['address'] ?? '';
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Avatar
              Center(child: Column(children: [
                CircleAvatar(radius: 44, backgroundColor: lightBlue,
                  child: Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: blue))),
                const SizedBox(height: 12),
                Text(user?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0B2E6B))),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Patient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: blue))),
              ])),
              const SizedBox(height: 24),

              // Read-only info
              _infoCard([
                _infoRow(Icons.badge_outlined, 'Patient ID', user?.userId ?? '—'),
                _infoRow(Icons.email_outlined, 'Email', user?.email ?? '—'),
                _infoRow(Icons.circle, 'Status', user?.isActive == true ? 'Active' : 'Inactive',
                    valueColor: user?.isActive == true ? Colors.green : Colors.red),
              ]),
              const SizedBox(height: 16),

              // Editable fields
              Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Contact Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: blue)),
                  const SizedBox(height: 12),
                  _editField(ctrl: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_outlined,
                      hint: 'e.g. +91 98765 43210', enabled: false, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _editField(ctrl: _addressCtrl, label: 'Address', icon: Icons.location_on_outlined,
                      hint: 'Your address', enabled: false, maxLines: 2),
                ])),
            ]),
          );
        },
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(children: List.generate(rows.length, (i) => Column(children: [
        rows[i],
        if (i < rows.length - 1) Divider(height: 16, color: Colors.grey.shade100),
      ]))));
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF1A1A2E))),
      ])),
    ]);
  }

  Widget _editField({required TextEditingController ctrl, required String label, required IconData icon,
      required String hint, bool enabled = true, TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl, keyboardType: keyboardType, maxLines: maxLines, enabled: enabled,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true, fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: blue, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 13),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}