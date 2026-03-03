import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminHomestayManagementScreen extends StatefulWidget {
  const AdminHomestayManagementScreen({super.key});

  @override
  State<AdminHomestayManagementScreen> createState() =>
      _AdminHomestayManagementScreenState();
}

class _AdminHomestayManagementScreenState
    extends State<AdminHomestayManagementScreen> {
  final _nameCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl  = TextEditingController();
  final _latCtrl      = TextEditingController();
  final _lngCtrl      = TextEditingController();
  final _rateCtrl     = TextEditingController();

  File?   _pickedImage;
  bool    _saving = false;
  double? _uploadProgress;

  final ImagePicker _picker = ImagePicker();

  static const Color deepBlue    = Color(0xFF0D47A1);
  static const Color mediumBlue  = Color(0xFF1565C0);
  static const Color lightBlue   = Color(0xFFE3F2FD);
  static const Color accentBlue  = Color(0xFF42A5F5);
  static const Color surfaceWhite = Color(0xFFF8FBFF);

  final _col = FirebaseFirestore.instance.collection('homestays');

  @override
  void dispose() {
    for (final c in [_nameCtrl, _locationCtrl, _contactCtrl, _latCtrl, _lngCtrl, _rateCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Select Image From',
                style: TextStyle(color: deepBlue, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _srcTile(Icons.photo_library_rounded, 'Gallery', () async {
                Navigator.pop(ctx);
                final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (f != null) setState(() => _pickedImage = File(f.path));
              })),
              const SizedBox(width: 12),
              Expanded(child: _srcTile(Icons.camera_alt_rounded, 'Camera', () async {
                Navigator.pop(ctx);
                final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (f != null) setState(() => _pickedImage = File(f.path));
              })),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _srcTile(IconData icon, String label, VoidCallback onTap) {
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
          Text(label, style: const TextStyle(color: deepBlue, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('homestay_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final task = ref.putFile(_pickedImage!, SettableMetadata(contentType: 'image/jpeg'));
    task.snapshotEvents.listen((s) {
      if (mounted) setState(() => _uploadProgress = s.bytesTransferred / s.totalBytes);
    });
    final snap = await task;
    setState(() => _uploadProgress = null);
    return await snap.ref.getDownloadURL();
  }

  Future<void> _addHomestay() async {
    if (_nameCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty ||
        _contactCtrl.text.trim().isEmpty || _rateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all required fields'),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final imageUrl = await _uploadImage();
      await _col.add({
        'name':      _nameCtrl.text.trim(),
        'location':  _locationCtrl.text.trim(),
        'contact':   _contactCtrl.text.trim(),
        'lat':       double.tryParse(_latCtrl.text.trim()) ?? 0.0,
        'lng':       double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
        'rate':      double.tryParse(_rateCtrl.text.trim()) ?? 0.0,
        'imageUrl':  imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final c in [_nameCtrl, _locationCtrl, _contactCtrl, _latCtrl, _lngCtrl, _rateCtrl]) {
        c.clear();
      }
      setState(() => _pickedImage = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Homestay added successfully'),
        backgroundColor: Colors.green, behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: $e'),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Homestay'),
        content: const Text('Are you sure you want to remove this homestay?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await _col.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      appBar: AppBar(
        backgroundColor: deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Homestay Management',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: Column(children: [
        // ── Form ──────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: deepBlue.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: deepBlue, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    const Text('Add New Homestay', style: TextStyle(color: deepBlue, fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 16),
                  _field(_nameCtrl, 'Name *', Icons.home_rounded),
                  const SizedBox(height: 12),
                  _field(_locationCtrl, 'Location / Hospital Nearby *', Icons.location_on_rounded),
                  const SizedBox(height: 12),
                  _field(_contactCtrl, 'Contact Number *', Icons.phone_rounded,
                      type: TextInputType.phone),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field(_latCtrl, 'Latitude', Icons.gps_fixed_rounded,
                        type: const TextInputType.numberWithOptions(decimal: true))),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_lngCtrl, 'Longitude', Icons.gps_not_fixed_rounded,
                        type: const TextInputType.numberWithOptions(decimal: true))),
                  ]),
                  const SizedBox(height: 12),
                  _field(_rateCtrl, 'Rate per Day (₹) *', Icons.currency_rupee_rounded,
                      type: TextInputType.number),
                  const SizedBox(height: 12),

                  // Image picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        const Icon(Icons.image_rounded, color: accentBlue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          _pickedImage != null ? _pickedImage!.path.split('/').last : 'Tap to pick image (optional)',
                          style: TextStyle(fontSize: 13, color: _pickedImage != null ? Colors.black87 : Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        )),
                        const Icon(Icons.upload_rounded, color: deepBlue, size: 20),
                      ]),
                    ),
                  ),
                  if (_pickedImage != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_pickedImage!, height: 110, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                  if (_uploadProgress != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _uploadProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(deepBlue)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepBlue, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _saving ? null : _addHomestay,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.add_circle_outline, size: 20),
                      label: Text(_saving ? 'Saving…' : 'Add Homestay',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),

              // ── List ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(children: [
                  const Icon(Icons.list_alt_rounded, color: deepBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text('Homestay List',
                      style: TextStyle(color: deepBlue, fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _col.orderBy('createdAt', descending: false).snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text('No homestays added yet',
                          style: TextStyle(color: Colors.grey.shade500))),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final imageUrl = data['imageUrl'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          border: const Border(left: BorderSide(color: deepBlue, width: 4)),
                          boxShadow: [BoxShadow(color: deepBlue.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, width: 42, height: 42, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholder())
                                : _placeholder(),
                          ),
                          title: Text(data['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('${data['location'] ?? ''} · ₹${data['rate'] ?? 0}/day',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          trailing: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                            ),
                            onPressed: () => _delete(docs[i].id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
      width: 42, height: 42, color: lightBlue,
      child: const Icon(Icons.house_outlined, color: deepBlue, size: 20));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: mediumBlue, fontWeight: FontWeight.w500, fontSize: 14),
        prefixIcon: Icon(icon, color: accentBlue, size: 20),
        filled: true, fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFBBDEFB), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: deepBlue, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }
}