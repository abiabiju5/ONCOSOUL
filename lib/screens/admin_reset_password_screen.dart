import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class AdminResetPasswordScreen extends StatefulWidget {
  const AdminResetPasswordScreen({super.key});

  @override
  State<AdminResetPasswordScreen> createState() =>
      _AdminResetPasswordScreenState();
}

class _AdminResetPasswordScreenState
    extends State<AdminResetPasswordScreen> {
  final _userIdController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _newPassword;
  String? _errorMessage;
  bool _resetSuccess = false;

  final Color _deepBlue = const Color(0xFF0D47A1);

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final userId = _userIdController.text.trim();

    if (userId.isEmpty) {
      setState(() => _errorMessage = 'Please enter a User ID.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _newPassword = null;
      _resetSuccess = false;
    });

    try {
      final newPassword = await _authService.resetPassword(userId);
      setState(() {
        _newPassword = newPassword;
        _resetSuccess = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        title: const Text('Reset User Password'),
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Instructions ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: _deepBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter the User ID to generate a new password. '
                      'The old password will be invalidated immediately.',
                      style: TextStyle(
                          fontSize: 13, color: _deepBlue),
                    ),
                  ),
                ],
              ),
            ),

            // ── Input Card ───────────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Identification',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _deepBlue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _userIdController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'User ID',
                        hintText: 'e.g. P1001, D2001, M3001',
                        prefixIcon:
                            Icon(Icons.fingerprint, color: _deepBlue),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setState(() {
                        _errorMessage = null;
                        _resetSuccess = false;
                        _newPassword = null;
                      }),
                    ),

                    // ── Error message ─────────────────────────────────────
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade400, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

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
                        onPressed: _isLoading ? null : _resetPassword,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.lock_reset),
                        label: Text(_isLoading
                            ? 'Resetting...'
                            : 'Generate New Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── New Password Card (shown on success) ──────────────────────────
            if (_resetSuccess && _newPassword != null) ...[
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
                            'Password Reset Successful',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      Text(
                        'User ID',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      Text(
                        _userIdController.text.trim().toUpperCase(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'New Password',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.green.shade200),
                              ),
                              child: Text(
                                _newPassword!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            color: _deepBlue,
                            onPressed: () =>
                                _copyToClipboard(_newPassword!),
                            tooltip: 'Copy password',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
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
                                color: Colors.orange.shade600,
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Share this new password privately with the user. '
                                'Their old password no longer works.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800),
                              ),
                            ),
                          ],
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
}