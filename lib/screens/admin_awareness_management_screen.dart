import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import 'awareness_screen.dart' show accentFor, iconFor;

class AdminAwarenessManagementScreen extends StatefulWidget {
  const AdminAwarenessManagementScreen({super.key});
  @override
  State<AdminAwarenessManagementScreen> createState() =>
      _AdminAwarenessManagementScreenState();
}

class _AdminAwarenessManagementScreenState
    extends State<AdminAwarenessManagementScreen> {
  // ── Form fields ────────────────────────────────────────────────────────────
  final _titleCtrl    = TextEditingController();
  final _categoryCtrl = TextEditingController();

  // Sections: each has a title + body controller
  final List<_SectionEntry> _sections = [_SectionEntry()];

  final ImagePicker _picker = ImagePicker();
  XFile?     _pickedFile;
  Uint8List? _previewBytes;
  bool       _saving         = false;
  double     _uploadProgress = 0.0;
  bool       _isUploading    = false;
  String?    _errorMessage;

  static const Color deepBlue   = Color(0xFF0D47A1);
  static const Color mediumBlue = Color(0xFF1565C0);
  static const Color lightBlue  = Color(0xFFE3F2FD);
  static const Color accentBlue = Color(0xFF42A5F5);

  final _collection =
      FirebaseFirestore.instance.collection('awareness_content');

  // ── Predefined categories ─────────────────────────────────────────────────
  static const _predefinedCategories = [
    'Breast Cancer', 'Lung Cancer', 'Skin Cancer', 'Cervical Cancer',
    'Colon Cancer', 'Prevention', 'Treatment', 'Mental Health',
    'Nutrition', 'General',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    for (final s in _sections) s.dispose();
    super.dispose();
  }

  // ── Image picker ───────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final f = await _picker.pickImage(
          source: source, imageQuality: 70, maxWidth: 1024, maxHeight: 1024);
      if (f == null || !mounted) return;
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      setState(() { _pickedFile = f; _previewBytes = bytes; _errorMessage = null; });
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Could not pick image: $e');
    }
  }

  Future<void> _showPickerSheet() => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select Image From',
              style: TextStyle(color: deepBlue, fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _sourceOption(Icons.photo_library_rounded,
                'Gallery', () => _pickImage(ImageSource.gallery))),
            const SizedBox(width: 12),
            Expanded(child: _sourceOption(Icons.camera_alt_rounded,
                'Camera', () => _pickImage(ImageSource.camera))),
          ]),
        ]),
      ),
    ),
  );

  Widget _sourceOption(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: lightBlue, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
          ),
          child: Column(children: [
            Icon(icon, color: deepBlue, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(
                color: deepBlue, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      );

  // ── Upload image ───────────────────────────────────────────────────────────
  Future<String?> _uploadImage() async {
    if (_pickedFile == null || _previewBytes == null) return null;
    if (mounted) setState(() { _isUploading = true; _uploadProgress = 0.0; });
    try {
      final url = await CloudinaryService.uploadBytes(
        bytes: _previewBytes!,
        folder: 'awareness_images',
        fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
      );
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 1.0; });
      return url;
    } catch (e) {
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 0.0; });
      rethrow;
    }
  }

  // ── Save new content ───────────────────────────────────────────────────────
  Future<void> _addContent() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (_titleCtrl.text.trim().isEmpty || _categoryCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill in Title and Category.');
      return;
    }
    if (_sections.every((s) => s.titleCtrl.text.trim().isEmpty &&
        s.bodyCtrl.text.trim().isEmpty)) {
      setState(() => _errorMessage = 'Add at least one section with content.');
      return;
    }

    setState(() => _saving = true);
    try {
      String imageUrl = '';
      if (_pickedFile != null) {
        try { imageUrl = await _uploadImage() ?? ''; }
        catch (e) {
          if (mounted) setState(() =>
              _errorMessage = 'Image upload failed: $e\nSaving without image…');
        }
      }

      final sectionsData = _sections
          .where((s) => s.titleCtrl.text.trim().isNotEmpty ||
              s.bodyCtrl.text.trim().isNotEmpty)
          .map((s) => {
            'title': s.titleCtrl.text.trim(),
            'body':  s.bodyCtrl.text.trim(),
          })
          .toList();

      // Also build legacy description for backward compatibility
      final desc = sectionsData
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value['title']}\n${e.value['body']}')
          .join('\n\n');

      await _collection.add({
        'title':       _titleCtrl.text.trim(),
        'category':    _categoryCtrl.text.trim(),
        'description': desc,
        'sections':    sectionsData,
        'imageUrl':    imageUrl,
        'createdAt':   FieldValue.serverTimestamp(),
      });

      // Reset
      _titleCtrl.clear();
      _categoryCtrl.clear();
      for (final s in _sections) s.dispose();
      _sections
        ..clear()
        ..add(_SectionEntry());

      if (mounted) {
        setState(() {
          _pickedFile = null; _previewBytes = null;
          _errorMessage = null; _uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Content added successfully ✓'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Edit existing content ──────────────────────────────────────────────────
  Future<void> _editContent(String docId, Map<String, dynamic> data) async {
    final titleCtrl    = TextEditingController(text: data['title']    ?? '');
    final categoryCtrl = TextEditingController(text: data['category'] ?? '');

    // Load existing sections or parse legacy
    List<_SectionEntry> editSections = [];
    final rawSections = data['sections'];
    if (rawSections is List && rawSections.isNotEmpty) {
      for (final s in rawSections) {
        editSections.add(_SectionEntry(
          title: s['title']?.toString() ?? '',
          body:  s['body']?.toString()  ?? '',
        ));
      }
    } else {
      // Parse from description
      final desc = data['description'] as String? ?? '';
      for (final block in desc.split(RegExp(r'\n\d+\.\s'))) {
        final lines = block.trim().split('\n');
        if (lines.isEmpty) continue;
        editSections.add(_SectionEntry(
          title: lines.first.replaceAll(RegExp(r'^\d+\.\s*'), '').trim(),
          body: lines.skip(1).join('\n').trim(),
        ));
      }
      if (editSections.isEmpty) {
        editSections.add(_SectionEntry(body: desc));
      }
    }
    if (editSections.isEmpty) editSections.add(_SectionEntry());

    String? editError;
    bool editSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                decoration: const BoxDecoration(
                  color: deepBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Edit Content',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w700))),
                  GestureDetector(onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 22)),
                ]),
              ),

              // Scrollable body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _field(titleCtrl, 'Title *', Icons.title_rounded),
                    const SizedBox(height: 10),
                    _categoryField(categoryCtrl, setDlg),
                    const SizedBox(height: 16),

                    // Sections
                    Row(children: [
                      Container(width: 4, height: 16,
                          decoration: BoxDecoration(color: deepBlue,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      const Text('Sections',
                          style: TextStyle(color: deepBlue, fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setDlg(() => editSections.add(_SectionEntry())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Row(mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: deepBlue, size: 14),
                              SizedBox(width: 4),
                              Text('Add Section',
                                  style: TextStyle(color: deepBlue,
                                      fontSize: 11, fontWeight: FontWeight.w600)),
                            ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    ...editSections.asMap().entries.map((e) =>
                        _SectionCard(
                          index: e.key,
                          entry: e.value,
                          canDelete: editSections.length > 1,
                          onDelete: () => setDlg(() => editSections.removeAt(e.key)),
                          onChanged: () => setDlg(() {}),
                        )),

                    if (editError != null)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(editError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ]),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: editSaving ? null : () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepBlue, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: editSaving ? null : () async {
                        if (titleCtrl.text.trim().isEmpty ||
                            categoryCtrl.text.trim().isEmpty) {
                          setDlg(() => editError = 'Fill in Title and Category.');
                          return;
                        }
                        setDlg(() { editSaving = true; editError = null; });
                        try {
                          final sectionsData = editSections
                              .where((s) => s.titleCtrl.text.trim().isNotEmpty ||
                                  s.bodyCtrl.text.trim().isNotEmpty)
                              .map((s) => {
                                'title': s.titleCtrl.text.trim(),
                                'body':  s.bodyCtrl.text.trim(),
                              }).toList();

                          final desc = sectionsData.asMap().entries
                              .map((e) =>
                                  '${e.key + 1}. ${e.value['title']}\n${e.value['body']}')
                              .join('\n\n');

                          await _collection.doc(docId).update({
                            'title':       titleCtrl.text.trim(),
                            'category':    categoryCtrl.text.trim(),
                            'description': desc,
                            'sections':    sectionsData,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Content updated ✓'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ));
                          }
                        } catch (e) {
                          setDlg(() {
                            editSaving = false;
                            editError = 'Update failed: $e';
                          });
                        }
                      },
                      icon: editSaving
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(editSaving ? 'Saving…' : 'Save Changes',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );

    titleCtrl.dispose();
    categoryCtrl.dispose();
    for (final s in editSections) s.dispose();
  }

  Future<void> _deleteContent(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Delete this content permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _collection.doc(docId).delete();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        backgroundColor: deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Awareness Management',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: Column(children: [

        // ── Upload form ──────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // Form card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: deepBlue.withValues(alpha: 0.08),
                      blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  // Card header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    decoration: const BoxDecoration(
                      color: deepBlue,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Text('Add New Content',
                          style: TextStyle(color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      _field(_titleCtrl, 'Article Title', Icons.title_rounded),
                      const SizedBox(height: 12),
                      _categoryField(_categoryCtrl, setState),
                      const SizedBox(height: 12),

                      // Image picker
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _saving ? null : _showPickerSheet,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFBBDEFB), width: 1.5),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(children: [
                                const Icon(Icons.image_rounded,
                                    color: accentBlue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(
                                  _pickedFile?.name ?? 'Tap to pick cover image',
                                  style: TextStyle(fontSize: 13,
                                      color: _pickedFile != null
                                          ? Colors.black87 : Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _saving ? null : _showPickerSheet,
                          child: Container(
                            height: 52, width: 52,
                            decoration: BoxDecoration(
                              color: _saving ? Colors.grey : deepBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.upload_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ]),
                      if (_previewBytes != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_previewBytes!,
                              height: 110, width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                      ],

                      // Upload progress
                      if (_saving && _pickedFile != null) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _uploadProgress > 0 ? _uploadProgress : null,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(deepBlue),
                            ),
                          )),
                          if (_uploadProgress > 0) ...[
                            const SizedBox(width: 8),
                            Text('${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 11,
                                    color: deepBlue, fontWeight: FontWeight.w600)),
                          ],
                        ]),
                      ],

                      // Error
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12))),
                            GestureDetector(
                              onTap: () => setState(() => _errorMessage = null),
                              child: const Icon(Icons.close,
                                  color: Colors.red, size: 16),
                            ),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // Sections card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: deepBlue.withValues(alpha: 0.06),
                      blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  // Sections header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.07),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.list_alt_rounded,
                          color: deepBlue, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Article Sections',
                          style: TextStyle(color: deepBlue, fontSize: 14,
                              fontWeight: FontWeight.w700))),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _sections.add(_SectionEntry())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: deepBlue,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Row(mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Add Section',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 11, fontWeight: FontWeight.w600)),
                            ]),
                        ),
                      ),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      ..._sections.asMap().entries.map((e) =>
                          _SectionCard(
                            index: e.key,
                            entry: e.value,
                            canDelete: _sections.length > 1,
                            onDelete: () =>
                                setState(() => _sections.removeAt(e.key)),
                            onChanged: () => setState(() {}),
                          )),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _saving ? null : _addContent,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.publish_rounded, size: 20),
                  label: Text(
                    _saving
                        ? (_isUploading
                            ? 'Uploading… ${(_uploadProgress * 100).toInt()}%'
                            : 'Saving…')
                        : 'Publish Content',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Existing content list ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(width: 4, height: 18,
                      decoration: BoxDecoration(color: deepBlue,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  const Text('Published Articles',
                      style: TextStyle(color: deepBlue, fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ]),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: _collection
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(child: Column(
                          mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.inbox_rounded, size: 50,
                            color: accentBlue.withValues(alpha: 0.4)),
                        const SizedBox(height: 10),
                        Text('No articles yet',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14)),
                      ])),
                    );
                  }
                  return Column(
                    children: docs.asMap().entries.map((e) {
                      final doc  = e.value;
                      final data = doc.data() as Map<String, dynamic>;
                      final cat  = data['category'] as String? ?? '';
                      final accent = accentFor(cat);
                      final imageUrl =
                          (data['imageUrl'] ?? '').toString().trim();
                      final sections = data['sections'];
                      final sectionCount = sections is List
                          ? sections.length : 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(children: [
                          // Left accent bar
                          Container(
                            width: 5,
                            height: 80,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(16)),
                            ),
                          ),
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              width: 52, height: 52,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _imgPlaceholder(accent))
                                  : _imgPlaceholder(accent),
                            ),
                          ),
                          // Info
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(data['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Color(0xFF0D1B3E))),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.10),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text(cat,
                                        style: TextStyle(
                                            color: accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 6),
                                  if (sectionCount > 0)
                                    Text('$sectionCount sections',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500)),
                                ]),
                              ]),
                            ),
                          ),
                          // Actions
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: lightBlue,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.edit_outlined,
                                    color: deepBlue, size: 16),
                              ),
                              onPressed: () => _editContent(doc.id, data),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red, size: 16),
                              ),
                              onPressed: () => _deleteContent(doc.id),
                            ),
                          ]),
                        ]),
                      );
                    }).toList(),
                  );
                },
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Category dropdown field ────────────────────────────────────────────────
  Widget _categoryField(TextEditingController ctrl, StateSetter setS) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: ctrl,
        onChanged: (_) => setS(() {}), // rebuild chips on every keystroke
        decoration: InputDecoration(
          labelText: 'Category',
          hintText: 'Type a category or pick one below',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          labelStyle: const TextStyle(
              color: mediumBlue, fontWeight: FontWeight.w500, fontSize: 14),
          prefixIcon: const Icon(Icons.category_rounded,
              color: accentBlue, size: 20),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: Colors.grey, size: 18),
                  tooltip: 'Clear category',
                  onPressed: () => setS(() {
                    ctrl.clear();
                  }),
                )
              : null,
          filled: true, fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFBBDEFB), width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: deepBlue, width: 2)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(
          'Or choose a predefined category:',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ),
      Wrap(
        spacing: 6, runSpacing: 6,
        children: _predefinedCategories.map((cat) {
          final selected = ctrl.text.trim().toLowerCase() ==
              cat.toLowerCase();
          final accent = accentFor(cat);
          return GestureDetector(
            onTap: () => setS(() {
              // Properly set text AND move cursor to end
              ctrl.value = TextEditingValue(
                text: cat,
                selection: TextSelection.collapsed(offset: cat.length),
              );
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? accent : accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? accent : accent.withValues(alpha: 0.25)),
              ),
              child: Text(cat,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : accent)),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _imgPlaceholder(Color accent) => Container(
      color: accent.withValues(alpha: 0.08),
      child: Center(child: Icon(Icons.article_rounded,
          color: accent.withValues(alpha: 0.4), size: 24)));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: mediumBlue, fontWeight: FontWeight.w500, fontSize: 14),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: accentBlue, size: 20) : null,
          filled: true, fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFBBDEFB), width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: deepBlue, width: 2)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontSize: 14),
      );
}

// ── Section entry model ───────────────────────────────────────────────────────
class _SectionEntry {
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;

  _SectionEntry({String title = '', String body = ''})
      : titleCtrl = TextEditingController(text: title),
        bodyCtrl  = TextEditingController(text: body);

  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
  }
}

// ── Section card widget ───────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final int index;
  final _SectionEntry entry;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _SectionCard({
    required this.index,
    required this.entry,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  static const Color deepBlue  = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color mediumBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Column(children: [
        // Section header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: deepBlue.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(
                  color: deepBlue, shape: BoxShape.circle),
              child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Text('Section ${index + 1}',
                style: const TextStyle(color: deepBlue, fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            if (canDelete)
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 16),
                ),
              ),
          ]),
        ),

        // Section title field
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: entry.titleCtrl,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: 'Section title  (e.g. What is Breast Cancer?)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.title_rounded,
                  color: accentBlue, size: 18),
              filled: true, fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFDDE3F0), width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: deepBlue, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),

        // Section body field
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: TextField(
            controller: entry.bodyCtrl,
            onChanged: (_) => onChanged(),
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Write section content here…\nUse - for bullet points',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true, fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFDDE3F0), width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: deepBlue, width: 1.5)),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ]),
    );
  }
}