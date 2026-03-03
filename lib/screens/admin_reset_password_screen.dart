import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminResetPasswordScreen extends StatefulWidget {
  const AdminResetPasswordScreen({super.key});

  @override
  State<AdminResetPasswordScreen> createState() =>
      _AdminResetPasswordScreenState();
}

class _AdminResetPasswordScreenState
    extends State<AdminResetPasswordScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);
  static const Color _purple = Color(0xFF6A1B9A);

  final _authService = AuthService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedDocId;   // Firestore document ID
  String? _selectedUserId;  // e.g. P1001
  String? _selectedName;
  bool _resetting = false;

  // Shown after successful reset
  String? _newPassword;
  String? _resetForName;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_selectedUserId == null) return;
    setState(() { _resetting = true; _newPassword = null; });
    try {
      final newPass = await _authService.resetPassword(_selectedUserId!);
      if (!mounted) return;
      setState(() {
        _newPassword    = newPass;
        _resetForName   = _selectedName;
        _selectedDocId  = null;
        _selectedUserId = null;
        _selectedName   = null;
        _searchQuery    = '';
        _searchCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: ${e.toString().replaceFirst("Exception: ", "")}'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Password copied to clipboard'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.w700, color: _deepBlue)),
        backgroundColor: Colors.white,
        foregroundColor: _deepBlue,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8EEF8)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Success banner ─────────────────────────────────────────
            if (_newPassword != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade300, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text('Password Reset — $_resetForName',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade800,
                              fontSize: 13)),
                    ]),
                    const SizedBox(height: 12),
                    const Text('New Password:',
                        style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(_newPassword!,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 1.5)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copy(_newPassword!),
                        icon: Icon(Icons.copy_outlined, color: Colors.green.shade700),
                        tooltip: 'Copy password',
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('⚠️  Share this new password with $_resetForName securely.',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.green.shade800,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Info banner ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: _deepBlue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search for a user and reset their password. A new password will be auto-generated — share it with the user manually.',
                    style: TextStyle(fontSize: 12.5, color: _deepBlue, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Search bar ─────────────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or User ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDDE3F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDDE3F0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _deepBlue, width: 1.5)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
            const SizedBox(height: 12),

            // ── Search results ─────────────────────────────────────────
            if (_searchQuery.isNotEmpty)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final userId = (data['userId'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) ||
                          userId.contains(_searchQuery);
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(child: Text('No users found.'));
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final docId  = docs[i].id;
                        final userId = data['userId'] ?? docId;
                        final name   = data['name'] ?? 'Unknown';
                        final role   = data['role'] ?? 'Patient';
                        final isSelected = _selectedDocId == docId;

                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedDocId  = docId;
                            _selectedUserId = userId;
                            _selectedName   = name;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected ? _deepBlue : const Color(0xFFE8EEF8),
                                  width: isSelected ? 1.5 : 1),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6)],
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundColor: _deepBlue.withValues(alpha: 0.1),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: _deepBlue, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    Text('ID: $userId',
                                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    Text(role,
                                        style: const TextStyle(fontSize: 11, color: Colors.black38)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: _deepBlue),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            // ── Selected user + Reset button ───────────────────────────
            if (_selectedUserId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EEF8)),
                ),
                child: Row(children: [
                  const Icon(Icons.person, color: _deepBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('User ID: $_selectedUserId',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _resetting ? null : _resetPassword,
                  icon: _resetting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_reset_rounded),
                  label: Text(
                    _resetting ? 'Resetting...' : 'Reset Password',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}