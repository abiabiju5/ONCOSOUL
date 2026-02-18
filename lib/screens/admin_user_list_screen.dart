import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() =>
      _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final _authService = AuthService();
  final Color _deepBlue = const Color(0xFF0D47A1);

  String _filterRole = 'All';
  String _searchQuery = '';

  // ✅ Super Admin removed — hospital admin should not see or manage it
  final List<String> _roles = [
    'All',
    UserRole.patient,
    UserRole.doctor,
    UserRole.medicalStaff,
    UserRole.admin,
  ];

  Color _roleColor(String role) {
    switch (role) {
      case UserRole.admin:
        return Colors.indigo;
      case UserRole.doctor:
        return Colors.teal;
      case UserRole.medicalStaff:
        return Colors.orange;
      case UserRole.patient:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case UserRole.admin:
        return Icons.manage_accounts;
      case UserRole.doctor:
        return Icons.medical_services_outlined;
      case UserRole.medicalStaff:
        return Icons.local_hospital_outlined;
      case UserRole.patient:
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }

  // ── Toggle active status ──────────────────────────────────────────────────
  Future<void> _toggleActive(AppUser user) async {
    final newStatus = !user.isActive;
    final action = newStatus ? 'activate' : 'deactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
            'Confirm ${newStatus ? "Activation" : "Deactivation"}'),
        content: Text(
            'Are you sure you want to $action the account for '
            '${user.name} (${user.userId})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newStatus ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _authService.setUserActive(user.userId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${user.name} has been '
                '${newStatus ? "activated" : "deactivated"}.'),
            backgroundColor:
                newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        title: const Text('Registered Users'),
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Search + Filter Bar ─────────────────────────────────────────
          Container(
            color: _deepBlue.withValues(alpha: 0.04),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or user ID…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
                const SizedBox(height: 10),
                // ✅ Role filter chips — Super Admin excluded
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roles
                        .map((r) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(r),
                                selected: _filterRole == r,
                                selectedColor:
                                    _deepBlue.withValues(alpha: 0.15),
                                onSelected: (_) => setState(
                                    () => _filterRole = r),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── User List ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _authService.getAllUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style:
                            const TextStyle(color: Colors.red)),
                  );
                }

                var users = snapshot.data ?? [];

                // ✅ Always hide Super Admin from this list
                users = users
                    .where(
                        (u) => u.role != UserRole.superAdmin)
                    .toList();

                // Apply role filter
                if (_filterRole != 'All') {
                  users = users
                      .where((u) => u.role == _filterRole)
                      .toList();
                }

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  users = users
                      .where((u) =>
                          u.name
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          u.userId
                              .toLowerCase()
                              .contains(_searchQuery))
                      .toList();
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No users found',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (ctx, i) {
                    final user = users[i];
                    final color = _roleColor(user.role);

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor:
                              color.withValues(alpha: 0.15),
                          radius: 24,
                          child: Icon(_roleIcon(user.role),
                              color: color, size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3),
                              decoration: BoxDecoration(
                                color: user.isActive
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                  color: user.isActive
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                user.isActive
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: user.isActive
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${user.userId}',
                                  style: const TextStyle(
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(
                                      alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  user.role,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Switch(
                          value: user.isActive,
                          activeThumbColor: Colors.green,
                          inactiveThumbColor:
                              Colors.red.shade300,
                          onChanged: (_) =>
                              _toggleActive(user),
                        ),
                      ),
                    );
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