import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/homestay_model.dart';

class AdminHomestayManagementScreen extends StatefulWidget {
  const AdminHomestayManagementScreen({super.key});

  @override
  State<AdminHomestayManagementScreen> createState() =>
      _AdminHomestayManagementScreenState();
}

class _AdminHomestayManagementScreenState
    extends State<AdminHomestayManagementScreen> {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final contactController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final rateController = TextEditingController();
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
                          setState(() => imageController.text = file.path);
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
                          setState(() => imageController.text = file.path);
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

  Widget _previewPlaceholder() {
    return Container(
      color: lightBlue,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: deepBlue, size: 36),
      ),
    );
  }

  Widget _listIconFallback() {
    return Container(
      color: lightBlue,
      child: const Icon(Icons.home_rounded, color: deepBlue, size: 28),
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
          'Homestay Management',
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
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
                                'Add New Homestay',
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
                            controller: nameController,
                            decoration: _inputDecoration(
                                'Homestay Name', Icons.home_rounded),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: locationController,
                            decoration: _inputDecoration(
                                'Location (Address)', Icons.location_on_rounded),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: contactController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                                'Contact Number', Icons.phone_rounded),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: rateController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecoration(
                                'Rate (₹ per day)', Icons.currency_rupee_rounded),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          // Lat & Lng side by side
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: latController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: _inputDecoration(
                                      'Latitude', Icons.explore_rounded),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: lngController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: _inputDecoration(
                                      'Longitude', Icons.explore_outlined),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Image Picker Row ──────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: imageController,
                                  readOnly: true,
                                  decoration: _inputDecoration(
                                    'Homestay Image',
                                    Icons.image_rounded,
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
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

                          // ── Image Preview ─────────────────────────────────
                          if (imageController.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 110,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFFBBDEFB),
                                      width: 1.5),
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
                              onPressed: addHomestay,
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              label: const Text(
                                'Add Homestay',
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
                        const Icon(Icons.holiday_village_rounded,
                            color: deepBlue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Homestay List',
                          style: TextStyle(
                            color: deepBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: lightBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${HomestayData.homestays.length} items',
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

                  // Homestay List
                  HomestayData.homestays.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.home_work_rounded,
                                  size: 60, color: accentBlue.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No homestays added yet',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: HomestayData.homestays.length,
                          itemBuilder: (context, index) {
                            final stay = HomestayData.homestays[index];
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image thumbnail or icon fallback
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: (stay.imagePath != null &&
                                                stay.imagePath!.isNotEmpty)
                                            ? (stay.imagePath!
                                                    .startsWith('assets/')
                                                ? Image.asset(
                                                    stay.imagePath!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        _listIconFallback(),
                                                  )
                                                : Image.file(
                                                    File(stay.imagePath!),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        _listIconFallback(),
                                                  ))
                                            : _listIconFallback(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stay.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          _infoRow(Icons.location_on_rounded,
                                              stay.location),
                                          const SizedBox(height: 3),
                                          _infoRow(
                                              Icons.phone_rounded, stay.contact),
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: lightBlue,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '₹${stay.rate.toStringAsFixed(0)} / day',
                                              style: const TextStyle(
                                                color: mediumBlue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Delete Button
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEBEE),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.red,
                                            size: 18),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          HomestayData.homestays.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: accentBlue),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void addHomestay() {
    if (nameController.text.isEmpty ||
        locationController.text.isEmpty ||
        contactController.text.isEmpty ||
        latController.text.isEmpty ||
        lngController.text.isEmpty ||
        rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    try {
      final double latitude = double.parse(latController.text);
      final double longitude = double.parse(lngController.text);
      final double rate = double.parse(rateController.text);

      setState(() {
        HomestayData.homestays.add(
          Homestay(
            name: nameController.text,
            location: locationController.text,
            contact: contactController.text,
            lat: latitude,
            lng: longitude,
            rate: rate,
            imagePath: imageController.text,
          ),
        );
      });

      nameController.clear();
      locationController.clear();
      contactController.clear();
      latController.clear();
      lngController.clear();
      rateController.clear();
      imageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Homestay added successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid numeric values'),
        ),
      );
    }
  }
}