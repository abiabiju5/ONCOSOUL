import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminDoctorManagementScreen extends StatefulWidget {
  const AdminDoctorManagementScreen({super.key});

  @override
  State<AdminDoctorManagementScreen> createState() =>
      _AdminDoctorManagementScreenState();
}

class _AdminDoctorManagementScreenState
    extends State<AdminDoctorManagementScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);
  static const Color _lightBlue = Color(0xFFE8F0FE);

  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // No orderBy — avoids composite index requirement.
  // We sort client-side after fetching.
  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: UserRole.doctor)
      .snapshots();

  Future<void> _toggleActive(String userId, bool current) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'isActive': !current});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(current ? 'Doctor deactivated' : 'Doctor activated'),
      backgroundColor: current ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _updateSpecialty(String userId, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Specialty',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'e.g. Oncologist',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _deepBlue, width: 1.5),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _deepBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'specialty': result});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Doctor Management',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────
          Container(
            color: _deepBlue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search doctors…',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                filled: true,
                fillColor: Colors.white12,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // ── Doctor list ──────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                var docs = snap.data?.docs ?? [];

                // Sort by name client-side (avoids composite index)
                docs = List.from(docs)..sort((a, b) {
                  final na = ((a.data() as Map)['name'] ?? '').toString().toLowerCase();
                  final nb = ((b.data() as Map)['name'] ?? '').toString().toLowerCase();
                  return na.compareTo(nb);
                });

                // Apply search filter
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final id = (data['userId'] ?? '').toString().toLowerCase();
                    final spec = (data['specialty'] ?? '').toString().toLowerCase();
                    return name.contains(_search) ||
                        id.contains(_search) ||
                        spec.contains(_search);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_search_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _search.isEmpty ? 'No doctors registered yet' : 'No doctors match "$_search"',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      ),
                    ]),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final userId = data['userId'] ?? docs[i].id;
                    final name = data['name'] ?? '—';
                    final specialty = data['specialty'] ?? 'Not set';
                    final isActive = data['isActive'] ?? true;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isActive
                                ? _deepBlue.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive ? _lightBlue : Colors.red.shade50,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14)),
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isActive
                                    ? _deepBlue.withValues(alpha: 0.12)
                                    : Colors.red.shade100,
                                child: Icon(Icons.medical_services_outlined,
                                    color: isActive ? _deepBlue : Colors.red,
                                    size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isActive
                                                  ? _deepBlue
                                                  : Colors.red.shade700)),
                                      Text('ID: $userId',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                    ]),
                              ),
                              // Active badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: isActive
                                          ? Colors.green.shade300
                                          : Colors.red.shade300),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isActive
                                          ? Colors.green.shade700
                                          : Colors.red.shade700),
                                ),
                              ),
                            ]),
                          ),

                          // Specialty row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Row(children: [
                              Icon(Icons.science_outlined,
                                  size: 15, color: Colors.grey.shade500),
                              const SizedBox(width: 8),
                              Text('Specialty: ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                              Expanded(
                                  child: Text(specialty,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600))),
                              GestureDetector(
                                onTap: () =>
                                    _updateSpecialty(docs[i].id, specialty),
                                child: const Icon(Icons.edit_outlined,
                                    size: 16, color: _deepBlue),
                              ),
                            ]),
                          ),

                          // Toggle active
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                            child: Row(children: [
                              Icon(
                                isActive
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                size: 15,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isActive
                                      ? 'Available for appointments'
                                      : 'Not available',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isActive
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Switch(
                                value: isActive,
                                activeColor: _deepBlue,
                                onChanged: (_) =>
                                    _toggleActive(docs[i].id, isActive),
                              ),
                            ]),
                          ),
                        ],
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