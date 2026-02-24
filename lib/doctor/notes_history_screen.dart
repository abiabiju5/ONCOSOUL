import 'package:flutter/material.dart';
import '../services/doctor_service.dart';

class NotesHistoryScreen extends StatefulWidget {
  const NotesHistoryScreen({super.key});

  @override
  State<NotesHistoryScreen> createState() => _NotesHistoryScreenState();
}

class _NotesHistoryScreenState extends State<NotesHistoryScreen> {
  static const Color _blue = Color(0xFF0D47A1);
  static const Color _bg = Color(0xFFF0F4FF);

  final _service = DoctorService();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return _formatDate(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _showNoteDetail(BuildContext context, ConsultationNote note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                CircleAvatar(
                  backgroundColor: _blue.withAlpha(30),
                  child: Text(
                    note.patientName.isNotEmpty
                        ? note.patientName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: _blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.patientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(_formatDate(note.createdAt),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ]),
                ),
              ]),
              const SizedBox(height: 16),
              const Text('Consultation Notes',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      note.notes.isNotEmpty
                          ? note.notes
                          : 'No notes recorded.',
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notes History',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Container(
            color: _blue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by patient name…',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Colors.white60),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Colors.white60),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withAlpha(30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ── Notes list ────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<ConsultationNote>>(
              stream: _service.allNotesStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Error: ${snap.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                var notes = snap.data ?? [];

                // Filter by search query
                if (_query.isNotEmpty) {
                  notes = notes
                      .where((n) =>
                          n.patientName.toLowerCase().contains(_query) ||
                          n.notes.toLowerCase().contains(_query))
                      .toList();
                }

                // Sort by most recent first
                notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'No notes match "$_query".'
                              : 'No consultation notes yet.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showNoteDetail(context, note),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: _blue.withAlpha(30),
                              child: Text(
                                note.patientName.isNotEmpty
                                    ? note.patientName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: _blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(note.patientName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                    ),
                                    Text(_timeAgo(note.createdAt),
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    note.notes.isNotEmpty
                                        ? note.notes
                                        : 'No notes recorded.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                        height: 1.4),
                                  ),
                                  if (note.updatedAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                          'Updated ${_timeAgo(note.updatedAt!)}',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.grey, size: 20),
                          ]),
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