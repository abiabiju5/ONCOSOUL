import 'package:flutter/material.dart';

class HospitalDashboard extends StatelessWidget {
  const HospitalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final Color deepBlue = const Color(0xFF0D47A1);
    final Color accentBlue = const Color(0xFF2E7DFF);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,

        // Branded AppBar title (same as Patient)
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volunteer_activism,
              size: 22,
              color: accentBlue,
            ),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Onco',
                    style: TextStyle(
                      color: deepBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: 'Soul',
                    style: TextStyle(
                      color: accentBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Hospital Panel',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: deepBlue,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Manage doctors, patients and medical records',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 24),

            // OPTIONS
            Expanded(
              child: ListView(
                children: [
                  optionBox(
                    icon: Icons.description_outlined,
                    title: 'Upload Medical Report',
                    subtitle: 'Add and manage patient reports',
                    color: Colors.teal.shade700,
                  ),
                  optionBox(
                    icon: Icons.medical_services_outlined,
                    title: 'Add Doctor',
                    subtitle: 'Register doctors under hospital',
                    color: Colors.blue.shade700,
                  ),
                  optionBox(
                    icon: Icons.people_outline,
                    title: 'Add Patient',
                    subtitle: 'Register and manage patients',
                    color: Colors.purple.shade700,
                  ),
                  optionBox(
                    icon: Icons.analytics_outlined,
                    title: 'Hospital Overview',
                    subtitle: 'View activity and records summary',
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STANDARD OPTION BOX (same as Patient)
  Widget optionBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Navigation later
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: .35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: .20),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: color,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color.withValues(alpha: .6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
