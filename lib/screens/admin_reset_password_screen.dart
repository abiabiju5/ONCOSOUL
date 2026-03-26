import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
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
  static const Color _purple   = Color(0xFF6A1B9A);

  // ── EmailJS credentials (same as admin_user_account_screen) ────────────
  static const String _emailjsServiceId  = 'service_xh5thzn';
  static const String _emailjsTemplateId = 'template_y0m05z3';
  static const String _emailjsPublicKey  = 'Qua-QCadcOD8GPY3b';

  final _authService = AuthService();
  final _searchCtrl  = TextEditingController();

  String  _searchQuery    = '';
  String? _selectedDocId;
  String? _selectedUserId;
  String? _selectedName;
  String? _selectedEmail;   // captured when user is selected from list
  String? _selectedRole;    // captured for the email template

  bool _resetting = false;

  // Shown after a successful reset
  String? _newPassword;
  String? _resetForName;
  String? _resetForEmail;
  bool?   _emailSent;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Send new password via EmailJS (same logic as create-user screen) ────
  Future<bool> _sendCredentialsEmail({
    required String toName,
    required String toEmail,
    required String userId,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id':  _emailjsServiceId,
          'template_id': _emailjsTemplateId,
          'user_id':     _emailjsPublicKey,
          'template_params': {
            'to_name':  toName,
            'to_email': toEmail,
            'user_id':  userId,
            'password': password,
            'role':     role,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Reset password + send email ─────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (_selectedUserId == null) return;
    setState(() { _resetting = true; _newPassword = null; _emailSent = null; });

    try {
      final newPass = await _authService.resetPassword(_selectedUserId!);
      if (!mounted) return;

      // Capture values before clearing selection state
      final name  = _selectedName  ?? '';
      final email = _selectedEmail ?? '';
      final role  = _selectedRole  ?? 'Patient';
      final uid   = _selectedUserId!;

      // Send new password to the user's email
      final sent = await _sendCredentialsEmail(
        toName:   name,
        toEmail:  email,
        userId:   uid,
        password: newPass,
        role:     role,
      );

      if (!mounted) return;
      setState(() {
        _newPassword    = newPass;
        _resetForName   = name;
        _resetForEmail  = email;
        _emailSent      = sent;
        _selectedDocId  = null;
        _selectedUserId = null;
        _selectedName   = null;
        _selectedEmail  = null;
        _selectedRole   = null;
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

            // ── Success banner ──────────────────────────────────────────
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
                    // Title
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

                    // New password row
                    const Text('New Password:',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
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
                        icon: Icon(Icons.copy_outlined,
                            color: Colors.green.shade700),
                        tooltip: 'Copy password',
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Email delivery status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_emailSent ?? false)
                            ? Colors.green.shade100
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: (_emailSent ?? false)
                                ? Colors.green.shade300
                                : Colors.orange.shade300),
                      ),
                      child: Row(children: [
                        Icon(
                          (_emailSent ?? false)
                              ? Icons.mark_email_read_outlined
                              : Icons.warning_amber_outlined,
                          size: 16,
                          color: (_emailSent ?? false)
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (_emailSent ?? false)
                                ? 'New password sent to ${_resetForEmail ?? _resetForName}'
                                : 'Email delivery failed — share the new password manually',
                            style: TextStyle(
                                fontSize: 12,
                                color: (_emailSent ?? false)
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Info banner ─────────────────────────────────────────────
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
                    'Search for a user and reset their password. A new password will be auto-generated and sent to the user\'s registered email.',
                    style: TextStyle(
                        fontSize: 12.5, color: _deepBlue, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Search bar ──────────────────────────────────────────────
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
                    borderSide:
                        const BorderSide(color: _deepBlue, width: 1.5)),
              ),
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
            ),
            const SizedBox(height: 12),

            // ── Search results ──────────────────────────────────────────
            if (_searchQuery.isNotEmpty)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['name'] ?? '').toString().toLowerCase();
                      final userId =
                          (data['userId'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) ||
                          userId.contains(_searchQuery);
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                          child: Text('No users found.'));
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final data =
                            docs[i].data() as Map<String, dynamic>;
                        final docId  = docs[i].id;
                        final userId = data['userId']  ?? docId;
                        final name   = data['name']    ?? 'Unknown';
                        final role   = data['role']    ?? 'Patient';
                        final email  = data['email']   ?? '';
                        final isSelected = _selectedDocId == docId;

                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedDocId  = docId;
                            _selectedUserId = userId;
                            _selectedName   = name;
                            _selectedEmail  = email;   // ← capture email
                            _selectedRole   = role;    // ← capture role
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE3F2FD)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? _deepBlue
                                      : const Color(0xFFE8EEF8),
                                  width: isSelected ? 1.5 : 1),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6)
                              ],
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundColor:
                                    _deepBlue.withValues(alpha: 0.1),
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: _deepBlue,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                    Text('ID: $userId',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                    Text(role,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black38)),
                                    if (email.isNotEmpty)
                                      Text(email,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black38)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: _deepBlue),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            // ── Selected user + Reset button ────────────────────────────
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
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        Text('User ID: $_selectedUserId',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                        if ((_selectedEmail ?? '').isNotEmpty)
                          Text(_selectedEmail!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black38)),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _resetting ? null : _resetPassword,
                  icon: _resetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_reset_rounded),
                  label: Text(
                    _resetting ? 'Resetting...' : 'Reset Password',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
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