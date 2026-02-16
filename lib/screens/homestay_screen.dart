import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomestayScreen extends StatelessWidget {
  const HomestayScreen({super.key});
final Color deepBlue = const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Nearby Homestays',
          style: TextStyle(
            fontSize: 20,                // ✅ font change
            fontWeight: FontWeight.w700, // ✅ font change
            color: deepBlue,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: IconThemeData(color: deepBlue),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.25,
          children: [
            homestayBox(
              context,
              image: 'assets/images/homestay1.jpg',
              name: 'CareNest',
              location: 'City Cancer Hospital',
              lat: 12.9716,
              lng: 77.5946,
            ),
            homestayBox(
              context,
              image: 'assets/images/homestay2.jpg',
              name: 'HopeStay',
              location: 'Apollo Oncology',
              lat: 12.9352,
              lng: 77.6245,
            ),
            homestayBox(
              context,
              image: 'assets/images/homestay3.jpg',
              name: 'Healing Homes',
              location: 'Medical College Rd',
              lat: 12.9987,
              lng: 77.5921,
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 HOMESTAY CARD
  Widget homestayBox(
    BuildContext context, {
    required String image,
    required String name,
    required String location,
    required double lat,
    required double lng,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: deepBlue.withValues(alpha:0.35),
          width: 2.5, // ✅ increased border size (fix)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: Image.asset(
              image,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),

          // NAME
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: deepBlue,
                fontSize: 14,
              ),
            ),
          ),

          // LOCATION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              location,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          // BUTTONS
          Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.call,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'CONTACT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepBlue,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact homestay (UI only)'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.directions,
                        size: 18,
                      ),
                      label: const Text(
                        'LOCATION',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        openGoogleMaps(lat, lng);
                      },
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

  // 📍 OPEN GOOGLE MAPS
  void openGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not open Google Maps';
    }
  }
}