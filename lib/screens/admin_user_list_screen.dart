import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);

  String _selectedRole = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // ✅ FIX: Values now match the UserRole constants stored in Firestore
  // ('Patient', 'Doctor', 'Medical Staff', 'Admin') instead of lowercase
  final List<Map<String, String>> _roleFilters = [
    {'value': 'all', 'label': 'All'},
    {'value': 'Patient', 'label': 'Patients'},
    {'value': 'Doctor', 'label': 'Doctors'},
    {'value': 'Medical Staff', 'label': 'Medical Staff'},
    {'value': 'Admin', 'label': 'Admins'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Derives the correct role from the userId prefix set at account creation.
  /// P → Patient, D → Doctor, M → Medical Staff, A → Admin, S → Super Admin
  String _roleFromUserId(String userId) {
    if (userId.isEmpty) return 'Patient';
    switch (userId[0].toUpperCase()) {
      case 'D': return 'Doctor';
      case 'M': return 'Medical Staff';
      case 'A': return 'Admin';
      case 'S': return 'Super Admin';
      default:  return 'Patient';
    }
  }

  /// If the stored role doesn't match the userId prefix, silently fix it.
  void _autoCorrectRole(String uid, String storedRole, String correctRole) {
    if (storedRole != correctRole) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'role': correctRole});
    }
  }

  Query<Map<String, dynamic>> get _query =>
      FirebaseFirestore.instance.collection('users');

  Future<void> _toggleActive(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isActive': !currentStatus});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          currentStatus ? 'Account deactivated.' : 'Account activated.'),
      backgroundColor:
          currentStatus ? Colors.orange.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _confirmToggle(
      String uid, String name, bool isActive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isActive ? 'Deactivate Account' : 'Activate Account',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: _deepBlue)),
        content: Text(
            '${isActive ? 'Deactivate' : 'Activate'} account for "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive
                  ? Colors.orange.shade700
                  : Colors.green.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isActive ? 'Deactivate' : 'Activate',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _toggleActive(uid, isActive);
  }

  Future<void> _changeRole(String uid, String name, String currentRole) async {
    String selectedRole = currentRole;
    final roles = ['Patient', 'Doctor', 'Medical Staff', 'Admin'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Change Role for "$name"',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _deepBlue, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: roles
                .map((role) => RadioListTile<String>(
                      value: role,
                      groupValue: selectedRole,
                      title: Text(role, style: const TextStyle(fontSize: 14)),
                      activeColor: _deepBlue,
                      onChanged: (v) => setDialogState(() => selectedRole = v!),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedRole != currentRole) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'role': selectedRole});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$name\'s role updated to $selectedRole.'),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showUserOptions(String uid, String name, String role, bool isActive) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text(role,
                style: TextStyle(color: _roleColor(role), fontSize: 12)),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined,
                  color: _deepBlue),
              title: const Text('Change Role'),
              onTap: () {
                Navigator.pop(context);
                _changeRole(uid, name, role);
              },
            ),
            ListTile(
              leading: Icon(
                isActive ? Icons.block : Icons.check_circle_outline,
                color: isActive ? Colors.orange : Colors.green,
              ),
              title: Text(
                  isActive ? 'Deactivate Account' : 'Activate Account'),
              onTap: () {
                Navigator.pop(context);
                _confirmToggle(uid, name, isActive);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Doctor':
        return const Color(0xFF1565C0);
      case 'Medical Staff':
        return const Color(0xFF00695C);
      case 'Admin':
        return const Color(0xFF6A1B9A);
      default: // 'Patient'
        return const Color(0xFF0277BD);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'Medical Staff':
        return 'Medical Staff';
      default:
        return role; // Already properly capitalised from Firestore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        title: const Text('User List',
            style:
                TextStyle(fontWeight: FontWeight.w700, color: _deepBlue)),
        backgroundColor: Colors.white,
        foregroundColor: _deepBlue,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8EEF8)),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F7FF),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          // Role filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _roleFilters
                    .map((r) => Padding(
                          padding:
                              const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(r['label']!),
                            selected: _selectedRole == r['value'],
                            onSelected: (_) => setState(
                                () => _selectedRole = r['value']!),
                            selectedColor: _deepBlue,
                            labelStyle: TextStyle(
                              color: _selectedRole == r['value']
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          // User list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs.toList();
                // Sort client-side by createdAt descending
                allDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'];
                  final bTime = bData['createdAt'];
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });
                final docs = allDocs.where((doc) {
                  // Filter by role using userId prefix (authoritative)
                  if (_selectedRole != 'all') {
                    if (_roleFromUserId(doc.id) != _selectedRole) return false;
                  }
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['name'] ?? '').toString().toLowerCase();
                  final email =
                      (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No users found',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;
                    final uid = docs[index].id;
                    final name = data['name'] ?? 'Unknown';
                    final email = data['email'] ?? '';
                    final phone = data['phone'] ?? '';
                    final storedRole = data['role'] ?? 'Patient';
                    // Derive authoritative role from userId prefix
                    final role = _roleFromUserId(uid);
                    // Silently fix Firestore if role was stored incorrectly
                    _autoCorrectRole(uid, storedRole, role);
                    final isActive = data['isActive'] ?? true;
                    final roleColor = _roleColor(role);

                    return GestureDetector(
                      onTap: () => _showUserOptions(uid, name, role, isActive),
                      child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor:
                              roleColor.withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: roleColor,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    roleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_roleLabel(role),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: roleColor)),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(email,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            if (phone.isNotEmpty)
                              Text(phone,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black38)),
                          ],
                        ),
                        trailing: GestureDetector(
                          onTap: () =>
                              _confirmToggle(uid, name, isActive),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isActive
                                      ? Colors.green.shade300
                                      : Colors.red.shade300),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.green.shade700
                                      : Colors.red.shade700),
                            ),
                          ),
                        ),
                      ),
                    )); // closes inner Container + GestureDetector
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