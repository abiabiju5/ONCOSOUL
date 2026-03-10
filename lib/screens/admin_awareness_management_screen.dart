import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class AdminAwarenessManagementScreen extends StatefulWidget {
  const AdminAwarenessManagementScreen({super.key});

  @override
  State<AdminAwarenessManagementScreen> createState() =>
      _AdminAwarenessManagementScreenState();
}

class _AdminAwarenessManagementScreenState
    extends State<AdminAwarenessManagementScreen> {
  final _titleCtrl       = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _categoryCtrl    = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile?     _pickedFile;
  Uint8List? _previewBytes;
  bool       _saving         = false;
  double     _uploadProgress = 0.0;
  bool       _isUploading    = false;
  String?    _errorMessage;

  static const Color deepBlue     = Color(0xFF0D47A1);
  static const Color mediumBlue   = Color(0xFF1565C0);
  static const Color lightBlue    = Color(0xFFE3F2FD);
  static const Color accentBlue   = Color(0xFF42A5F5);
  static const Color surfaceWhite = Color(0xFFF8FBFF);

  final _collection =
      FirebaseFirestore.instance.collection('awareness_content');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final f = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (f == null || !mounted) return;
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedFile   = f;
        _previewBytes = bytes;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Could not pick image: $e');
    }
  }

  Future<void> _showPickerSheet() {
    return showModalBottomSheet(
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
  }

  Widget _sourceOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
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
  }

  // ── Upload to Cloudinary ──────────────────────────────────────────────────

  Future<String?> _uploadImage() async {
    if (_pickedFile == null || _previewBytes == null) return null;

    if (mounted) setState(() { _isUploading = true; _uploadProgress = 0.0; });

    try {
      final url = await CloudinaryService.uploadBytes(
        bytes:    _previewBytes!,
        folder:   'awareness_images',
        fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 1.0; });
      return url;
    } catch (e) {
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 0.0; });
      rethrow;
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _addContent() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (_titleCtrl.text.trim().isEmpty ||
        _descriptionCtrl.text.trim().isEmpty ||
        _categoryCtrl.text.trim().isEmpty) {
      setState(() =>
          _errorMessage = 'Please fill in Title, Category and Description.');
      return;
    }

    setState(() => _saving = true);
    try {
      String imageUrl = '';
      if (_pickedFile != null) {
        try {
          imageUrl = await _uploadImage() ?? '';
        } catch (e) {
          if (mounted) setState(() =>
              _errorMessage = 'Image upload failed: $e\nSaving without image…');
        }
      }

      await _collection.add({
        'title':       _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'category':    _categoryCtrl.text.trim(),
        'imageUrl':    imageUrl,
        'createdAt':   FieldValue.serverTimestamp(),
      });

      _titleCtrl.clear();
      _descriptionCtrl.clear();
      _categoryCtrl.clear();

      if (mounted) {
        setState(() {
          _pickedFile    = null;
          _previewBytes  = null;
          _errorMessage  = null;
          _uploadProgress = 0.0;
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

  Future<void> _editContent(String docId, Map<String, dynamic> data) async {
    final titleCtrl       = TextEditingController(text: data['title']       ?? '');
    final descriptionCtrl = TextEditingController(text: data['description'] ?? '');
    final categoryCtrl    = TextEditingController(text: data['category']    ?? '');

    String? editError;
    bool editSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          title: Row(children: [
            Container(width: 4, height: 20,
                decoration: BoxDecoration(color: deepBlue,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Text('Edit Awareness Content',
                style: TextStyle(color: deepBlue, fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 8),
              _field(titleCtrl, 'Title *', Icons.title_rounded),
              const SizedBox(height: 10),
              _field(categoryCtrl, 'Category *', Icons.category_rounded),
              const SizedBox(height: 10),
              _field(descriptionCtrl, 'Description *',
                  Icons.description_rounded, maxLines: 3),
              if (editError != null) ...[
                const SizedBox(height: 10),
                Container(
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
              ],
              const SizedBox(height: 8),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: editSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: deepBlue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
              onPressed: editSaving ? null : () async {
                if (titleCtrl.text.trim().isEmpty ||
                    categoryCtrl.text.trim().isEmpty ||
                    descriptionCtrl.text.trim().isEmpty) {
                  setStateDialog(() => editError =
                      'Please fill in Title, Category and Description.');
                  return;
                }
                setStateDialog(() { editSaving = true; editError = null; });
                try {
                  await _collection.doc(docId).update({
                    'title':       titleCtrl.text.trim(),
                    'description': descriptionCtrl.text.trim(),
                    'category':    categoryCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Content updated successfully ✓'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  setStateDialog(() {
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
          ],
        ),
      ),
    );

    titleCtrl.dispose();
    descriptionCtrl.dispose();
    categoryCtrl.dispose();
  }

  Future<void> _deleteContent(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Delete this content?'),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
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

        // ── Form ──────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: deepBlue.withValues(alpha: 0.08),
                blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Container(width: 4, height: 20,
                  decoration: BoxDecoration(color: deepBlue,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text('Add New Content',
                  style: TextStyle(color: deepBlue, fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            _field(_titleCtrl, 'Title', Icons.title_rounded),
            const SizedBox(height: 12),
            _field(_categoryCtrl, 'Category', Icons.category_rounded),
            const SizedBox(height: 12),

            // Image picker row
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: GestureDetector(
                  onTap: _saving ? null : _showPickerSheet,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFBBDEFB), width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(children: [
                      const Icon(Icons.image_rounded,
                          color: accentBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        _pickedFile?.name ?? 'Tap to pick image',
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
                      color: Colors.white, size: 24),
                ),
              ),
            ]),

            // Preview
            if (_previewBytes != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_previewBytes!,
                    height: 110, width: double.infinity, fit: BoxFit.cover),
              ),
            ],

            // Progress bar
            if (_saving && _pickedFile != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(deepBlue),
                    ),
                  ),
                ),
                if (_uploadProgress > 0) ...[
                  const SizedBox(width: 8),
                  Text('${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 11,
                          color: deepBlue, fontWeight: FontWeight.w600)),
                ],
              ]),
              const SizedBox(height: 4),
              Text(
                _isUploading
                    ? (_uploadProgress > 0
                        ? 'Uploading to Cloudinary…'
                        : 'Connecting…')
                    : 'Saving…',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
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
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12))),
                  GestureDetector(
                    onTap: () => setState(() => _errorMessage = null),
                    child: const Icon(Icons.close, color: Colors.red, size: 16),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 12),
            _field(_descriptionCtrl, 'Description',
                Icons.description_rounded, maxLines: 3),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepBlue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _addContent,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add_circle_outline, size: 20),
                label: Text(
                  _saving
                      ? (_isUploading
                          ? 'Uploading… ${(_uploadProgress * 100).toInt()}%'
                          : 'Saving…')
                      : 'Add Content',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ]),
        ),

        // ── List header ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(children: [
            const Icon(Icons.list_alt_rounded, color: deepBlue, size: 20),
            const SizedBox(width: 8),
            const Text('Content List',
                style: TextStyle(color: deepBlue, fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
        ),

        // ── List ──────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _collection
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: Colors.red)));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Column(
                    mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inbox_rounded, size: 60,
                      color: accentBlue.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No content yet',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 15)),
                ]));
              }
              return ListView.builder(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final imageUrl = (data['imageUrl'] ?? '').toString().trim();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                          left: BorderSide(color: deepBlue, width: 4)),
                      boxShadow: [BoxShadow(
                          color: deepBlue.withValues(alpha: 0.06),
                          blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl,
                                width: 42, height: 42, fit: BoxFit.cover,
                                loadingBuilder: (_, child, p) =>
                                    p == null ? child : _imgPlaceholder(),
                                errorBuilder: (_, __, ___) => _imgPlaceholder())
                            : _imgPlaceholder(),
                      ),
                      title: Text(data['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: lightBlue,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(data['category'] ?? '',
                            style: const TextStyle(
                                color: mediumBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: lightBlue,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.edit_outlined,
                                color: deepBlue, size: 18),
                          ),
                          onPressed: () => _editContent(
                              docs[i].id,
                              docs[i].data() as Map<String, dynamic>),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red, size: 18),
                          ),
                          onPressed: () => _deleteContent(docs[i].id),
                        ),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _imgPlaceholder() => Container(
      width: 42, height: 42, color: lightBlue,
      child: const Icon(Icons.article_rounded, color: deepBlue, size: 20));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: mediumBlue, fontWeight: FontWeight.w500, fontSize: 14),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: accentBlue, size: 20)
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
    );
  }
}