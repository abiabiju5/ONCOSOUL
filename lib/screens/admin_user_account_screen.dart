import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminUserAccountScreen extends StatefulWidget {
  const AdminUserAccountScreen({super.key});

  @override
  State<AdminUserAccountScreen> createState() =>
      _AdminUserAccountScreenState();
}

class _AdminUserAccountScreenState
    extends State<AdminUserAccountScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);

  // ── EmailJS credentials ── replace with your own ──────────────────
  static const String _emailjsServiceId  = 'YOUR_SERVICE_ID';
  static const String _emailjsTemplateId = 'YOUR_TEMPLATE_ID';
  static const String _emailjsPublicKey  = 'YOUR_PUBLIC_KEY';
  // ──────────────────────────────────────────────────────────────────

  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _regIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _selectedRole = 'patient';
  bool   _loading      = false;

  // Generated password shown to admin after creation
  String? _generatedPassword;

  final List<Map<String, String>> _roles = [
    {'value': 'patient',  'label': 'Patient'},
    {'value': 'doctor',   'label': 'Doctor'},
    {'value': 'medical',  'label': 'Medical Staff'},
    {'value': 'admin',    'label': 'Admin'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regIdCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Password generator ─────────────────────────────────────────────
  // Format: FirstLetter(capital) + RegID + random 2-digit number
  // Example: Name=Alice, RegID=REG001 → AREG001847
  String _generatePassword(String name, String regId) {
    final firstLetter = name.trim()[0].toUpperCase();
    final randomNum   = (10 + Random().nextInt(90)).toString(); // 10–99
    return '$firstLetter$regId$randomNum';
  }

  // ── Send email via EmailJS ─────────────────────────────────────────
  Future<bool> _sendCredentialsEmail({
    required String toName,
    required String toEmail,
    required String password,
    required String role,
  }) async {
    const url =
        'https://api.emailjs.com/api/v1.0/email/send';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost', // required by EmailJS
        },
        body: jsonEncode({
          'service_id':  _emailjsServiceId,
          'template_id': _emailjsTemplateId,
          'user_id':     _emailjsPublicKey,
          'template_params': {
            'to_name':  toName,
            'to_email': toEmail,
            'password': password,
            'role':     role[0].toUpperCase() + role.substring(1),
          },
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Main create user flow ──────────────────────────────────────────
  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading           = true;
      _generatedPassword = null;
    });

    final name   = _nameCtrl.text.trim();
    final regId  = _regIdCtrl.text.trim();
    final email  = _emailCtrl.text.trim();
    final phone  = _phoneCtrl.text.trim();
    final role   = _selectedRole;

    // 1. Generate password
    final password = _generatePassword(name, regId);

    try {
      // 2. Create Firebase Auth account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    email,
        password: password,
      );
      final uid = credential.user!.uid;

      // 3. Save to Firestore 'users' collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'uid':       uid,
        'name':      name,
        'regId':     regId,
        'email':     email,
        'phone':     phone,
        'role':      role,
        'isActive':  true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. If doctor, also save to 'doctors' collection
      if (role == 'doctor') {
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(uid)
            .set({
          'uid':       uid,
          'name':      name,
          'regId':     regId,
          'email':     email,
          'phone':     phone,
          'isActive':  true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 5. Send credentials email
      final emailSent = await _sendCredentialsEmail(
        toName:   name,
        toEmail:  email,
        password: password,
        role:     role,
      );

      if (!mounted) return;

      // 6. Show generated password to admin
      setState(() => _generatedPassword = password);

      _showSuccess(emailSent
          ? 'Account created & credentials sent to $email'
          : 'Account created. Email failed — share password manually.');

      // 7. Clear form
      _formKey.currentState!.reset();
      _nameCtrl.clear();
      _regIdCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      setState(() => _selectedRole = 'patient');

    } on FirebaseAuthException catch (e) {
      String message = 'Failed to create account.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'Generated password is too weak.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }
      _showError(message);
    } catch (e) {
      _showError('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        title: const Text('Create User Account',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: _deepBlue)),
        backgroundColor: Colors.white,
        foregroundColor: _deepBlue,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(height: 1, color: const Color(0xFFE8EEF8)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Password preview banner ──────────────────────────
              if (_generatedPassword != null)
                _PasswordBanner(password: _generatedPassword!),

              if (_generatedPassword != null)
                const SizedBox(height: 16),

              // ── Info card ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: _deepBlue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Password is auto-generated as:\n'
                        'FirstLetter(Name) + RegID + 2-digit number\n'
                        'e.g.  Alice + REG001  →  AREG001847',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: _deepBlue,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form card ────────────────────────────────────────
              _sectionCard(children: [

                _label('Full Name'),
                _textField(
                  controller: _nameCtrl,
                  hint: 'Enter full name',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),

                _label('Registration ID'),
                _textField(
                  controller: _regIdCtrl,
                  hint: 'e.g. REG001 / DOC042',
                  icon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Registration ID is required'
                      : null,
                ),
                const SizedBox(height: 16),

                _label('Email Address'),
                _textField(
                  controller: _emailCtrl,
                  hint: 'Enter email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!v.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('Phone Number'),
                _textField(
                  controller: _phoneCtrl,
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone is required'
                      : null,
                ),
                const SizedBox(height: 16),

                _label('Role'),
                _roleDropdown(),
              ]),

              const SizedBox(height: 24),

              // ── Submit button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _createUser,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Create Account',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Widget _roleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3F0)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        decoration: const InputDecoration(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
        items: _roles
            .map((r) => DropdownMenuItem(
                  value: r['value'],
                  child: Text(r['label']!),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedRole = v!),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B3E))),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon:
          Icon(icon, size: 20, color: Colors.grey.shade500),
      filled: true,
      fillColor: const Color(0xFFF5F7FF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFDDE3F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFDDE3F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _deepBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400)),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint, icon),
      validator: validator,
    );
  }
}

// ── Password Banner Widget ─────────────────────────────────────────────────────
class _PasswordBanner extends StatefulWidget {
  final String password;
  const _PasswordBanner({required this.password});

  @override
  State<_PasswordBanner> createState() => _PasswordBannerState();
}

class _PasswordBannerState extends State<_PasswordBanner> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle,
                  color: Colors.green.shade700, size: 18),
              const SizedBox(width: 8),
              Text('Account Created Successfully',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Generated Password:',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.green.shade200),
                  ),
                  child: Text(
                    _visible
                        ? widget.password
                        : '•' * widget.password.length,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Show/hide toggle
              IconButton(
                onPressed: () =>
                    setState(() => _visible = !_visible),
                icon: Icon(
                  _visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.green.shade700,
                ),
                tooltip: _visible ? 'Hide' : 'Show',
              ),
              // Copy button
              IconButton(
                onPressed: () {
                  // Copy to clipboard
                  // Add: import 'package:flutter/services.dart';
                  // Then: Clipboard.setData(ClipboardData(text: widget.password));
                },
                icon: Icon(Icons.copy_outlined,
                    color: Colors.green.shade700),
                tooltip: 'Copy password',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '📧 Credentials have been sent to the user\'s email.',
            style: TextStyle(
                fontSize: 11.5,
                color: Colors.green.shade700,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}