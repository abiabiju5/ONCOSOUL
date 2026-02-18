import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/awareness_model.dart';

class AdminAwarenessManagementScreen extends StatefulWidget {
  const AdminAwarenessManagementScreen({super.key});

  @override
  State<AdminAwarenessManagementScreen> createState() =>
      _AdminAwarenessManagementScreenState();
}

class _AdminAwarenessManagementScreenState
    extends State<AdminAwarenessManagementScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final imageController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  // Color theme
  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color mediumBlue = Color(0xFF1565C0);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color surfaceWhite = Color(0xFFF8FBFF);

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: mediumBlue,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: accentBlue, size: 20),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBBDEFB), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: deepBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Opens a bottom sheet for the user to choose Gallery or Camera
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Image From',
                style: TextStyle(
                  color: deepBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _imageSourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? file = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (file != null) {
                          setState(() {
                            imageController.text = file.path;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _imageSourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? file = await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 85,
                        );
                        if (file != null) {
                          setState(() {
                            imageController.text = file.path;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: deepBlue, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: deepBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      appBar: AppBar(
        backgroundColor: deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Awareness Management',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          // Form Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: deepBlue.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: deepBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Add New Content',
                        style: TextStyle(
                          color: deepBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: titleController,
                    decoration: _inputDecoration('Title', Icons.title_rounded),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: categoryController,
                    decoration: _inputDecoration('Category', Icons.category_rounded),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // ── Image Picker Row ──────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: imageController,
                          readOnly: true,
                          decoration: _inputDecoration(
                            'Image Path (assets/images/...)',
                            Icons.image_rounded,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Upload button
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: deepBlue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: deepBlue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.upload_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Image Preview ─────────────────────────────────────────
                  if (imageController.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFBBDEFB), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: imageController.text.startsWith('assets/')
                            ? Image.asset(
                                imageController.text,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _previewPlaceholder(),
                              )
                            : Image.file(
                                File(imageController.text),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _previewPlaceholder(),
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                        'Description', Icons.description_rounded),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 18),

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepBlue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: deepBlue.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: addContent,
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text(
                        'Add Content',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.list_alt_rounded, color: deepBlue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Content List',
                  style: TextStyle(
                    color: deepBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${AwarenessData.contents.length} items',
                    style: const TextStyle(
                      color: deepBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: AwarenessData.contents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 60, color: accentBlue.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No content added yet',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: AwarenessData.contents.length,
                    itemBuilder: (context, index) {
                      final content = AwarenessData.contents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: const Border(
                            left: BorderSide(color: deepBlue, width: 4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: deepBlue.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.article_rounded,
                                color: deepBlue, size: 22),
                          ),
                          title: Text(
                            content.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: lightBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                content.category,
                                style: const TextStyle(
                                  color: mediumBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          isThreeLine: false,
                          trailing: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red, size: 18),
                            ),
                            onPressed: () {
                              setState(() {
                                AwarenessData.contents.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _previewPlaceholder() {
    return Container(
      color: lightBlue,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: deepBlue, size: 36),
      ),
    );
  }

  void addContent() {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        categoryController.text.isEmpty ||
        imageController.text.isEmpty) {
      return;
    }

    setState(() {
      AwarenessData.contents.add(
        AwarenessContent(
          title: titleController.text,
          description: descriptionController.text,
          category: categoryController.text,
          imagePath: imageController.text,
        ),
      );
    });

    titleController.clear();
    descriptionController.clear();
    categoryController.clear();
    imageController.clear();
  }
}