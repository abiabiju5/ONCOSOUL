import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomestayScreen extends StatelessWidget {
  const HomestayScreen({super.key});

  static const Color _navy = Color(0xFF0D47A1);
  static const Color _ice  = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'nearby stays',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _navy,
            letterSpacing: 0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: _navy),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _homestayCard(
            context,
            image: 'assets/images/homestay1.jpg',
            name: 'CareNest',
            ratePerDay: 850,
            lat: 12.9716,
            lng: 77.5946,
          ),
          const SizedBox(height: 14),
          _homestayCard(
            context,
            image: 'assets/images/homestay2.jpg',
            name: 'HopeStay',
            ratePerDay: 1200,
            lat: 12.9352,
            lng: 77.6245,
          ),
          const SizedBox(height: 14),
          _homestayCard(
            context,
            image: 'assets/images/homestay3.jpg',
            name: 'Healing Homes',
            ratePerDay: 950,
            lat: 12.9987,
            lng: 77.5921,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _homestayCard(
    BuildContext context, {
    required String image,
    required String name,
    required int ratePerDay,
    required double lat,
    required double lng,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── IMAGE ──────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Image.asset(
              image,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 170,
                color: _ice,
                child: const Icon(Icons.home_rounded,
                    size: 48, color: _navy),
              ),
            ),
          ),

          // ── INFO ROW ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + rate
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.bed_rounded,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Accommodation · Stay',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rate badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _ice,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹$ratePerDay',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _navy,
                        ),
                      ),
                      Text(
                        'per day',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── DIVIDER ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(color: Colors.grey.shade100, height: 1),
          ),

          // ── BUTTONS ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Contact
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.call_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Contact',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contacting $name...'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Location
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.directions_rounded,
                          size: 16, color: _navy),
                      label: const Text(
                        'Directions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        side: BorderSide(
                            color: _navy.withValues(alpha: 0.3), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _openGoogleMaps(lat, lng),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not open Google Maps';
    }
  }
}