import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class HomestayScreen extends StatelessWidget {
  const HomestayScreen({super.key});

  static const Color _navy = Color(0xFF0D47A1);
  static const Color _ice  = Color(0xFFE3F2FD);

  Future<void> _openMap(double lat, double lng, String name) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Nearby Stays',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _navy,
                letterSpacing: 0.4)),
        iconTheme: const IconThemeData(color: _navy),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey.shade100, height: 1)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('homestays')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.house_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No homestays available yet',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name     = data['name'] ?? '—';
              final location = data['location'] ?? '—';
              final contact  = data['contact'] ?? '';
              final rate     = (data['rate'] ?? 0).toDouble();
              final lat      = (data['lat'] ?? 0.0).toDouble();
              final lng      = (data['lng'] ?? 0.0).toDouble();
              // Trim to avoid accidental whitespace in stored URL
              final imageUrl = (data['imageUrl'] ?? '').toString().trim();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                      color: _navy.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4))],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Hero image with loading + error states
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                    child: _HeroImage(imageUrl: imageUrl),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Name + rate
                      Row(children: [
                        Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _navy))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: _ice,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('₹${rate.toStringAsFixed(0)}/day',
                              style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(location,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600))),
                      ]),
                      const SizedBox(height: 10),
                      // Contact number display
                      if (contact.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _ice,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _navy.withValues(alpha: 0.15)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                  color: _navy,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.phone_rounded,
                                  size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Contact Number',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500)),
                                Text(contact,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: _navy,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5)),
                              ],
                            ),
                          ]),
                        ),
                      const SizedBox(height: 12),
                      // Action buttons
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: contact.isNotEmpty
                                ? () => _call(contact)
                                : null,
                            icon: const Icon(Icons.phone_outlined, size: 15),
                            label: const Text('Call',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _navy,
                              side: const BorderSide(color: _navy),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (lat != 0 || lng != 0)
                                ? () => _openMap(lat, lng, name)
                                : null,
                            icon: const Icon(Icons.map_outlined, size: 15),
                            label: const Text('Directions',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Hero image with loading spinner + graceful error fallback ─────────────────
class _HeroImage extends StatelessWidget {
  final String imageUrl;
  const _HeroImage({required this.imageUrl});

  static const Color _navy = Color(0xFF0D47A1);
  static const Color _ice  = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _placeholder();
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 150,
      fit: BoxFit.cover,
      // Show spinner while downloading
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        final percent = progress.expectedTotalBytes != null
            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
            : null;
        return Container(
          width: double.infinity, height: 150, color: _ice,
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                value: percent, strokeWidth: 2.5,
                color: _navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Loading image…',
                style: TextStyle(fontSize: 11, color: _navy)),
          ])),
        );
      },
      // Graceful fallback if URL is broken / expired
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
      height: 150, color: _ice,
      child: const Center(
          child: Icon(Icons.house_outlined, size: 48, color: _navy)));
}