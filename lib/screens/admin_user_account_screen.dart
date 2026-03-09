import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AdminUserAccountScreen extends StatefulWidget {
  const AdminUserAccountScreen({super.key});

  @override
  State<AdminUserAccountScreen> createState() =>
      _AdminUserAccountScreenState();
}

class _AdminUserAccountScreenState extends State<AdminUserAccountScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);

  // ── EmailJS credentials — replace with your own ───────────────────────────
  static const String _emailjsServiceId  = 'service_xh5thzn';
  static const String _emailjsTemplateId = 'template_y0m05z3';
  static const String _emailjsPublicKey  = 'Qua-QCadcOD8GPY3b';
  // ─────────────────────────────────────────────────────────────────────────

  final _authService  = AuthService();
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _regIdCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _specialtyCtrl = TextEditingController();

  String _selectedRole = UserRole.patient;
  bool   _loading      = false;

  // Shown after successful creation
  String? _createdUserId;
  String? _createdPassword;
  bool?   _emailSent;
  String  _lastEmail = '';

  final List<String> _roles = [
    UserRole.patient,
    UserRole.doctor,
    UserRole.medicalStaff,
    UserRole.admin,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regIdCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _specialtyCtrl.dispose();
    super.dispose();
  }

  // ── Send credentials via EmailJS ─────────────────────────────────────────
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

  // ── Create user flow ─────────────────────────────────────────────────────
  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();

    setState(() {
      _loading         = true;
      _createdUserId   = null;
      _createdPassword = null;
      _emailSent       = null;
    });

    try {
      // 1. Create user in Firestore via AuthService
      final user = await _authService.createUser(
        name:           _nameCtrl.text.trim(),
        role:           _selectedRole,
        registrationId: _regIdCtrl.text.trim(),
        email:          _emailCtrl.text.trim(),
        specialty:      _selectedRole == UserRole.doctor ? _specialtyCtrl.text.trim() : null,
        phone:          _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      );

      // 2. Send credentials email
      final sent = await _sendCredentialsEmail(
        toName:   user.name,
        toEmail:  email,
        userId:   user.userId,
        password: user.password,
        role:     _selectedRole,
      );

      if (!mounted) return;

      setState(() {
        _createdUserId   = user.userId;
        _createdPassword = user.password;
        _emailSent       = sent;
        _lastEmail       = email;
      });

      // Clear form
      _nameCtrl.clear();
      _regIdCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _specialtyCtrl.clear();
      _formKey.currentState!.reset();
      setState(() => _selectedRole = UserRole.patient);

    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        title: const Text('Create User Account',
            style: TextStyle(fontWeight: FontWeight.w700, color: _deepBlue)),
        backgroundColor: Colors.white,
        foregroundColor: _deepBlue,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8EEF8)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Success banner ───────────────────────────────────────
              if (_createdUserId != null) ...[
                _SuccessBanner(
                  userId:    _createdUserId!,
                  password:  _createdPassword!,
                  emailSent: _emailSent ?? false,
                  email:     _lastEmail,
                ),
                const SizedBox(height: 16),
              ],

              // ── Info card ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBD0F8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: _deepBlue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF1A1A2E),
                              height: 1.5),
                          children: [
                            TextSpan(
                                text: 'Password is auto-generated as:\n',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            TextSpan(
                                text: 'FirstLetter(Name) + RegID + 2-digit number\n'),
                            TextSpan(
                                text: 'e.g.  Alice + REG001  →  AREG00147',
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Form card ────────────────────────────────────────────
              Container(
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
                  children: [

                    _label('Full Name'),
                    _textField(
                      controller: _nameCtrl,
                      hint: 'e.g. Akshaya Anil',
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _label('Registration ID'),
                    _textField(
                      controller: _regIdCtrl,
                      hint: 'e.g. 1001',
                      icon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Registration ID is required'
                          : null,
                    ),
                    const SizedBox(height: 4),
                    // Live User ID preview
                    ValueListenableBuilder(
                      valueListenable: _regIdCtrl,
                      builder: (_, __, ___) {
                        final regId = _regIdCtrl.text.trim();
                        if (regId.isEmpty) return const SizedBox.shrink();
                        final prefix = RolePrefix.getPrefix(_selectedRole);
                        return Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            'User ID will be: $prefix${regId.toUpperCase()}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: _deepBlue,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Email Address'),
                    _textField(
                      controller: _emailCtrl,
                      hint: 'user@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$')
                            .hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Phone Number (Optional)'),
                    _textField(
                      controller: _phoneCtrl,
                      hint: 'e.g. +91 98765 43210',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    _label('Role'),
                    _roleDropdown(),

                    // Specialty field — only for Doctors
                    if (_selectedRole == UserRole.doctor) ...[
                      const SizedBox(height: 16),
                      _label('Specialty'),
                      _textField(
                        controller: _specialtyCtrl,
                        hint: 'e.g. Oncologist, Surgeon',
                        icon: Icons.medical_services_outlined,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Specialty is required for doctors'
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _createUser,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.person_add_outlined, size: 20),
                  label: Text(
                    _loading ? 'Creating…' : 'Create Account & Send Email',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
        items: _roles
            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
            .toList(),
        onChanged: (v) => setState(() => _selectedRole = v!),
      ),
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
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
      filled: true,
      fillColor: const Color(0xFFF5F7FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _deepBlue, width: 1.5)),
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(hint, icon),
      validator: validator,
    );
  }
}

// ── Success Banner ────────────────────────────────────────────────────────────
class _SuccessBanner extends StatefulWidget {
  final String userId;
  final String password;
  final bool   emailSent;
  final String email;
  const _SuccessBanner({
    required this.userId,
    required this.password,
    required this.emailSent,
    required this.email,
  });

  @override
  State<_SuccessBanner> createState() => _SuccessBannerState();
}

class _SuccessBannerState extends State<_SuccessBanner> {
  bool _passwordVisible = false;

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied to clipboard'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

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
          Row(children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
            const SizedBox(width: 8),
            Text('Account Created Successfully',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 12),

          _credRow(
            label: 'User ID',
            value: widget.userId,
            onCopy: () => _copy(widget.userId, 'User ID'),
            isPassword: false,
            visible: true,
            onToggle: null,
          ),
          const SizedBox(height: 8),

          _credRow(
            label: 'Password',
            value: widget.password,
            onCopy: () => _copy(widget.password, 'Password'),
            isPassword: true,
            visible: _passwordVisible,
            onToggle: () =>
                setState(() => _passwordVisible = !_passwordVisible),
          ),
          const SizedBox(height: 12),

          // Email delivery status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.emailSent
                  ? Colors.green.shade100
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: widget.emailSent
                      ? Colors.green.shade300
                      : Colors.orange.shade300),
            ),
            child: Row(children: [
              Icon(
                widget.emailSent
                    ? Icons.mark_email_read_outlined
                    : Icons.warning_amber_outlined,
                size: 16,
                color: widget.emailSent
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.emailSent
                      ? 'Credentials sent to ${widget.email}'
                      : 'Email delivery failed — share credentials manually',
                  style: TextStyle(
                      fontSize: 12,
                      color: widget.emailSent
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _credRow({
    required String label,
    required String value,
    required VoidCallback onCopy,
    required bool isPassword,
    required bool visible,
    required VoidCallback? onToggle,
  }) {
    return Row(children: [
      SizedBox(
        width: 70,
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600)),
      ),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            isPassword && !visible ? '•' * value.length : value,
            style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1),
          ),
        ),
      ),
      if (onToggle != null)
        IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.green.shade700,
            size: 20,
          ),
        ),
      IconButton(
        onPressed: onCopy,
        icon: Icon(Icons.copy_outlined, color: Colors.green.shade700, size: 20),
        tooltip: 'Copy $label',
      ),
    ]);
  }
}