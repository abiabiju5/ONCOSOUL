import 'package:flutter/material.dart';

import 'doctor/appointments_screen.dart';
import 'doctor/consultations_page.dart';
import 'doctor/patients_page.dart';
import 'doctor/medical_report_page.dart';

import 'models/report_model.dart';
import 'models/patient_model.dart';
import 'login.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final Color deepBlue = const Color(0xFF0D47A1);
    final Color accentBlue = const Color(0xFF2E7DFF);

    final List<ReportModel> johnReports = [
      ReportModel(
        title: "Blood Test Report",
        date: "2025-02-10",
        path: "",
      ),
      ReportModel(
        title: "X-Ray Report",
        date: "2025-02-08",
        path: "",
      ),
    ];

    final List<ReportModel> sarahReports = [
      ReportModel(
        title: "CT Scan Report",
        date: "2025-02-05",
        path: "",
      ),
    ];

    final List<PatientModel> patients = [
      PatientModel(
        id: "P001",
        name: "John Doe",
        reports: johnReports,
      ),
      PatientModel(
        id: "P002",
        name: "Sarah Smith",
        reports: sarahReports,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital, color: accentBlue),
            const SizedBox(width: 6),
            Text(
              'Doctor Dashboard',
              style: TextStyle(
                color: deepBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [

          /// 🔔 Notification Icon Added
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No new notifications"),
                ),
              );
            },
          ),

          /// 🚪 Logout Button (Unchanged)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            optionBox(
              context,
              icon: Icons.video_call_outlined,
              title: 'Online Consultation',
              subtitle: 'Consult patients online',
              color: Colors.blue.shade700,
              screen: ConsultationsPage(),
            ),
            optionBox(
              context,
              icon: Icons.description_outlined,
              title: 'View Reports',
              subtitle: 'Access medical reports',
              color: Colors.teal.shade700,
              screen: MedicalReportsPage(
                patients: patients,
              ),
            ),
            optionBox(
              context,
              icon: Icons.people_outline,
              title: 'My Patients',
              subtitle: 'View patient list',
              color: Colors.purple.shade700,
              screen: PatientsPage(),
            ),
            optionBox(
              context,
              icon: Icons.event_available_outlined,
              title: 'Appointments',
              subtitle: 'Manage appointments',
              color: Colors.green.shade700,
              screen: AppointmentsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget optionBox(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget screen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.20),
                ),
                child: Icon(icon, size: 26, color: color),
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
                color: color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
