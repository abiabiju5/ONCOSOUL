import 'package:flutter/material.dart';
import 'screens/online_consultation_screen.dart';
import 'screens/view_reports_screen.dart';
import 'screens/homestay_screen.dart';
import 'screens/community_forum_screen.dart';
import 'screens/awareness_screen.dart';

class PatientDashboard extends StatelessWidget {
  final String userName;

  const PatientDashboard({
    super.key,
    required this.userName,
  });

  static const Color primaryBlue = Color(0xFF1E5AA8);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double bannerHeight;
    double titleSize;
    double subtitleSize;

    if (screenWidth < 600) {
      bannerHeight = 220;
      titleSize = 26;
      subtitleSize = 14;
    } else if (screenWidth < 1100) {
      bannerHeight = 250;
      titleSize = 30;
      subtitleSize = 16;
    } else {
      bannerHeight = 280;
      titleSize = 34;
      subtitleSize = 17;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 213, 230, 243),
              Color.fromARGB(255, 192, 213, 236),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [

                // ================= HEADER =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Row(
                        children: const [
                          Icon(Icons.volunteer_activism, color: primaryBlue),
                          SizedBox(width: 6),
                          Text(
                            "OncoSoul",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 4, 46, 100),
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Stack(
                            children: [
                              const Icon(Icons.notifications_none, size: 26),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    "1",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(width: 14),
                          Row(
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const CircleAvatar(
                                radius: 18,
                                backgroundImage:
                                    AssetImage("assets/images/profile.png"),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // ================= HERO BANNER =================
                Container(
                  width: double.infinity,
                  height: bannerHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            "assets/images/dashboard_bg.jpg",
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 205, 241, 239).withValues(alpha:0.9),
                                  const Color.fromARGB(255, 239, 250, 247).withValues(alpha:0.6),
                                  const Color.fromARGB(255, 239, 247, 244).withValues(alpha:0.1),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Hello, $userName",
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "We’re here to support your care journey",
                                style: TextStyle(fontSize: subtitleSize),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ================= OPTION CARDS =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [

                      Row(
                        children: [
                          Expanded(
                            child: dashboardCard(
                              context,
                              Icons.video_call,
                              "Online Consultation",
                              const OnlineConsultationScreen(),
                              const Color.fromARGB(255, 12, 58, 150),
                              const Color.fromARGB(255, 148, 171, 211),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: dashboardCard(
                              context,
                              Icons.description,
                              "View Reports",
                              const ViewReportsScreen(),
                              const Color.fromARGB(255, 3, 124, 68),
                              const Color.fromARGB(255, 127, 219, 142),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: dashboardCard(
                              context,
                              Icons.home,
                              "Accommodation",
                              const HomestayScreen(),
                              const Color.fromARGB(255, 207, 111, 32),
                              const Color.fromARGB(255, 238, 197, 151),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: dashboardCard(
                              context,
                              Icons.people,
                              "Community Forum",
                              const CommunityForumScreen(),
                              const Color.fromARGB(255, 126, 115, 14),
                              const Color.fromARGB(255, 234, 245, 137),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: dashboardCard(
                              context,
                              Icons.health_and_safety,
                              "Awareness",
                              const AwarenessScreen(),
                              const Color.fromARGB(255, 196, 39, 117),
                              const Color.fromARGB(255, 218, 137, 161),
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Spacer(),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
    Color iconColor,
    Color circleColor,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        height: 130,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 229, 238, 240).withValues(alpha:0.95),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha:0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}