import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class AdminUserAccountScreen extends StatefulWidget {
  const AdminUserAccountScreen({super.key});

  @override
  State<AdminUserAccountScreen> createState() =>
      _AdminUserAccountScreenState();
}

class _AdminUserAccountScreenState extends State<AdminUserAccountScreen> {
  String _selectedRole = UserRole.patient;

  final _nameController = TextEditingController();
  final _regIdController = TextEditingController();

  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  AppUser? _createdUser;

  // ── Roles selectable by admin ─────────────────────────────────────────────
  final List<String> _roles = [
    UserRole.patient,
    UserRole.doctor,
    UserRole.medicalStaff,
  ];

  final Color _deepBlue = const Color(0xFF0D47A1);

  @override
  void dispose() {
    _nameController.dispose();
    _regIdController.dispose();
    super.dispose();
  }

  // ── Create user in Firestore ─────────────────────────────────────────────
  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _createdUser = null;
    });

    try {
      final user = await _authService.createUser(
        name: _nameController.text.trim(),
        role: _selectedRole,
        registrationId: _regIdController.text.trim(),
      );

      setState(() => _createdUser = user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ User ${user.userId} created successfully!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _regIdController.clear();
    setState(() {
      _selectedRole = UserRole.patient;
      _createdUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        title: const Text('Create User Account'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Form Card ────────────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New User Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _deepBlue,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Role Selector ──────────────────────────────────────
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'User Role',
                          prefixIcon: Icon(Icons.badge_outlined,
                              color: _deepBlue),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _roles
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedRole = val!),
                      ),
                      const SizedBox(height: 16),

                      // ── Full Name ──────────────────────────────────────────
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon:
                              Icon(Icons.person_outline, color: _deepBlue),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter the full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Registration ID ────────────────────────────────────
                      TextFormField(
                        controller: _regIdController,
                        decoration: InputDecoration(
                          labelText: 'Registration ID',
                          hintText: 'e.g. 1001',
                          prefixIcon:
                              Icon(Icons.tag_outlined, color: _deepBlue),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          helperText:
                              'User ID will be: ${RolePrefix.getPrefix(_selectedRole)}[Registration ID]',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a registration ID';
                          }
                          if (v.trim().length < 3) {
                            return 'Registration ID must be at least 3 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Generate Button ────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _deepBlue,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isLoading ? null : _createUser,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.person_add_alt_1),
                          label: Text(
                              _isLoading ? 'Creating...' : 'Create & Save User'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Credentials Card (shown after creation) ───────────────────────
            if (_createdUser != null) ...[
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Credentials Generated',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      _credentialRow(
                          'Name', _createdUser!.name, Icons.person),
                      const SizedBox(height: 12),
                      _credentialRow(
                          'Role', _createdUser!.role, Icons.badge),
                      const SizedBox(height: 12),
                      _credentialRow(
                        'User ID',
                        _createdUser!.userId,
                        Icons.fingerprint,
                        copyable: true,
                      ),
                      const SizedBox(height: 12),
                      _credentialRow(
                        'Password',
                        _createdUser!.password,
                        Icons.lock_outline,
                        copyable: true,
                        sensitive: true,
                      ),

                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange.shade600, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Share these credentials privately with the user. '
                                'They can be reset later if needed.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Create Another User'),
                          onPressed: _clearForm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _credentialRow(
    String label,
    String value,
    IconData icon, {
    bool copyable = false,
    bool sensitive = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _deepBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
              Text(
                sensitive ? '••••••••  ($value)' : value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            color: _deepBlue,
            onPressed: () => _copyToClipboard(value, label),
            tooltip: 'Copy $label',
          ),
      ],
    );
  }
}