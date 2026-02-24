import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/app_user_session.dart';

// ── SeedDataScreen ─────────────────────────────────────────────────────────────
// Run this ONCE to populate Firestore with realistic sample data so every
// doctor-dashboard page has content to display.
//
// How to use:
//   1. Add a temporary button on the dashboard that navigates here, e.g.:
//        ElevatedButton(
//          onPressed: () => Navigator.push(context,
//              MaterialPageRoute(builder: (_) => const SeedDataScreen())),
//          child: const Text('Seed Sample Data'),
//        )
//   2. Open the page and tap "Seed All Sample Data".
//   3. Remove the button (and optionally this file) once done.

class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  final _db = FirebaseFirestore.instance;
  bool _loading = false;
  final List<String> _log = [];

  static const Color _green = Color(0xFF1B8A5A);

  void _addLog(String msg) {
    setState(() => _log.add(msg));
  }

  // ── Top-level seed ──────────────────────────────────────────────────────────

  Future<void> _seedAll() async {
    setState(() {
      _loading = true;
      _log.clear();
    });

    try {
      final doctorId = AppUserSession.currentUser?.userId ?? 'D0001';
      final doctorName = AppUserSession.currentUser?.name ?? 'Sample Doctor';

      // 1. Patients
      final patients = await _seedPatients();
      _addLog('✅ Seeded ${patients.length} patients');

      // 2. Appointments
      await _seedAppointments(doctorId, doctorName, patients);
      _addLog('✅ Seeded appointments (Today, Upcoming, Completed, Cancelled)');

      // 3. Medical Reports
      await _seedMedicalReports(patients);
      _addLog('✅ Seeded medical reports');

      // 4. Consultation Summaries
      await _seedConsultationSummaries(patients, doctorName);
      _addLog('✅ Seeded consultation summaries');

      // 5. Doctor Notes
      await _seedDoctorNotes(doctorId, doctorName, patients);
      _addLog('✅ Seeded doctor notes');

      // 6. Prescriptions
      await _seedPrescriptions(doctorId, doctorName, patients);
      _addLog('✅ Seeded prescriptions');

      // 7. Notifications for doctor
      await _seedNotifications(doctorId);
      _addLog('✅ Seeded notifications');

      _addLog('');
      _addLog('🎉 All done! Refresh the dashboard pages to see data.');
    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Patients ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _seedPatients() async {
    final patients = [
      {
        'userId': 'P0001',
        'name': 'Ananya Krishnan',
        'email': 'ananya.k@example.com',
        'phone': '+91 98765 43210',
        'role': 'Patient',
        'isActive': true,
        'gender': 'Female',
        'age': 34,
        'bloodGroup': 'B+',
        'address': '12, MG Road, Kochi, Kerala',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'P0002',
        'name': 'Rajesh Menon',
        'email': 'rajesh.m@example.com',
        'phone': '+91 91234 56789',
        'role': 'Patient',
        'isActive': true,
        'gender': 'Male',
        'age': 52,
        'bloodGroup': 'O+',
        'address': '45, Palarivattom, Ernakulam',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'P0003',
        'name': 'Priya Nair',
        'email': 'priya.nair@example.com',
        'phone': '+91 94400 12345',
        'role': 'Patient',
        'isActive': true,
        'gender': 'Female',
        'age': 28,
        'bloodGroup': 'A-',
        'address': '7, Thrissur Road, Palakkad',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'P0004',
        'name': 'Suresh Pillai',
        'email': 'suresh.p@example.com',
        'phone': '+91 99876 54321',
        'role': 'Patient',
        'isActive': true,
        'gender': 'Male',
        'age': 61,
        'bloodGroup': 'AB+',
        'address': '33, Beach Road, Kozhikode',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'P0005',
        'name': 'Deepa George',
        'email': 'deepa.g@example.com',
        'phone': '+91 97766 88990',
        'role': 'Patient',
        'isActive': true,
        'gender': 'Female',
        'age': 45,
        'bloodGroup': 'O-',
        'address': '89, Cantonment, Thiruvananthapuram',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final p in patients) {
      await _db.collection('users').doc(p['userId'] as String).set(p, SetOptions(merge: true));
    }
    return patients;
  }

  // ── Appointments ────────────────────────────────────────────────────────────

  Future<void> _seedAppointments(
    String doctorId,
    String doctorName,
    List<Map<String, dynamic>> patients,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final appts = [
      // ── TODAY (Pending — shows in consultation queue) ──────────────────
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[0],
        date: today.add(const Duration(hours: 9)),
        slot: '9:00 AM',
        status: 'Pending',
      ),
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[1],
        date: today.add(const Duration(hours: 10)),
        slot: '10:00 AM',
        status: 'Pending',
      ),
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[2],
        date: today.add(const Duration(hours: 11, minutes: 30)),
        slot: '11:30 AM',
        status: 'Pending',
      ),

      // ── UPCOMING (future dates, Pending) ──────────────────────────────
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[3],
        date: today.add(const Duration(days: 2, hours: 14)),
        slot: '2:00 PM',
        status: 'Pending',
      ),
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[4],
        date: today.add(const Duration(days: 3, hours: 9)),
        slot: '9:00 AM',
        status: 'Pending',
      ),
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[0],
        date: today.add(const Duration(days: 5, hours: 10)),
        slot: '10:00 AM',
        status: 'Pending',
      ),

      // ── COMPLETED (past dates) ────────────────────────────────────────
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[1],
        date: today.subtract(const Duration(days: 3, hours: -9)),
        slot: '9:00 AM',
        status: 'Completed',
      ),
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[2],
        date: today.subtract(const Duration(days: 5, hours: -11)),
        slot: '11:00 AM',
        status: 'Completed',
      ),
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[3],
        date: today.subtract(const Duration(days: 7, hours: -10)),
        slot: '10:30 AM',
        status: 'Completed',
      ),
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[4],
        date: today.subtract(const Duration(days: 10, hours: -9)),
        slot: '9:00 AM',
        status: 'Completed',
      ),

      // ── CANCELLED ─────────────────────────────────────────────────────
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[0],
        date: today.subtract(const Duration(days: 2, hours: -14)),
        slot: '2:00 PM',
        status: 'Cancelled',
      ),
      _appt(
        doctorId: doctorId,
        doctorName: doctorName,
        patient: patients[3],
        date: today.add(const Duration(days: 7, hours: 15)),
        slot: '3:00 PM',
        status: 'Cancelled',
      ),
    ];

    for (final a in appts) {
      await _db.collection('appointments').add(a);
    }
  }

  Map<String, dynamic> _appt({
    required String doctorId,
    required String doctorName,
    required Map<String, dynamic> patient,
    required DateTime date,
    required String slot,
    required String status,
  }) =>
      {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'patientId': patient['userId'],
        'patientName': patient['name'],
        'date': Timestamp.fromDate(date),
        'slot': slot,
        'status': status,
        'bookedAt': FieldValue.serverTimestamp(),
      };

  // ── Medical Reports ─────────────────────────────────────────────────────────

  Future<void> _seedMedicalReports(List<Map<String, dynamic>> patients) async {
    final now = DateTime.now();
    final reports = [
      {
        'patientId': patients[0]['userId'],
        'patientName': patients[0]['name'],
        'reportType': 'CBC (Complete Blood Count)',
        'labName': 'Metropolis Labs',
        'notes': 'Haemoglobin slightly low at 10.8 g/dL. Follow up in 4 weeks.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'patientId': patients[0]['userId'],
        'patientName': patients[0]['name'],
        'reportType': 'Tumour Marker (CA-125)',
        'labName': 'SRL Diagnostics',
        'notes': 'CA-125 level: 42 U/mL. Slightly elevated. Monitor closely.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt': Timestamp.fromDate(now.subtract(const Duration(days: 12))),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'patientId': patients[1]['userId'],
        'patientName': patients[1]['name'],
        'reportType': 'PET-CT Scan',
        'labName': 'Aster Medcity Radiology',
        'notes': 'No new metastatic lesions detected. Primary site stable.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt': Timestamp.fromDate(now.subtract(const Duration(days: 8))),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'patientId': patients[1]['userId'],
        'patientName': patients[1]['name'],
        'reportType': 'Liver Function Test (LFT)',
        'labName': 'Lakeshore Lab',
        'notes': 'SGPT: 56 U/L (slightly elevated). SGOT: 42 U/L. Review diet.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'patientId': patients[2]['userId'],
        'patientName': patients[2]['name'],
        'reportType': 'Mammogram',
        'labName': 'Amrita Imaging Centre',
        'notes': 'BIRADS 3 – Probably benign. Recommend 6-month follow-up.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'patientId': patients[3]['userId'],
        'patientName': patients[3]['name'],
        'reportType': 'PSA (Prostate Specific Antigen)',
        'labName': 'Vijaya Diagnostics',
        'notes': 'PSA: 6.8 ng/mL. Mildly elevated. Biopsy recommended.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt': Timestamp.fromDate(now.subtract(const Duration(days: 20))),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'patientId': patients[4]['userId'],
        'patientName': patients[4]['name'],
        'reportType': 'Chest X-Ray',
        'labName': 'Sunrise Hospital Radiology',
        'notes': 'No pleural effusion. Lung fields clear bilaterally.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'patientId': patients[4]['userId'],
        'patientName': patients[4]['name'],
        'reportType': 'MRI Brain',
        'labName': 'Aster Medcity Radiology',
        'notes': 'No intracranial mass lesion. White matter changes noted – age related.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final r in reports) {
      await _db.collection('medical_reports').add(r);
    }
  }

  // ── Consultation Summaries ──────────────────────────────────────────────────

  Future<void> _seedConsultationSummaries(
    List<Map<String, dynamic>> patients,
    String doctorName,
  ) async {
    final now = DateTime.now();
    final summaries = [
      {
        'patientId': patients[0]['userId'],
        'patientName': patients[0]['name'],
        'doctorName': doctorName,
        'visitDate': '${now.subtract(const Duration(days: 10)).day}/'
            '${now.subtract(const Duration(days: 10)).month}/'
            '${now.subtract(const Duration(days: 10)).year}',
        'visitTime': '09:00 AM',
        'chiefComplaint': 'Fatigue, pelvic pain and irregular menstrual cycle for 3 months.',
        'clinicalFindings':
            'Mild pallor. Abdomen soft, non-tender. Pelvic exam reveals adnexal fullness on the right.',
        'diagnosis': 'Suspected ovarian cyst with secondary anaemia.',
        'treatmentGiven':
            'Iron supplementation prescribed. USG pelvis ordered. Referred to gynaecology.',
        'nurseNotes': 'Patient appeared anxious. Counselled regarding procedure. BP: 110/70.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      },
      {
        'patientId': patients[1]['userId'],
        'patientName': patients[1]['name'],
        'doctorName': doctorName,
        'visitDate': '${now.subtract(const Duration(days: 7)).day}/'
            '${now.subtract(const Duration(days: 7)).month}/'
            '${now.subtract(const Duration(days: 7)).year}',
        'visitTime': '10:30 AM',
        'chiefComplaint': 'Follow-up after 2nd cycle of chemotherapy. Nausea and hair loss.',
        'clinicalFindings':
            'Grade 2 alopecia. Mild nausea – manageable. Performance status ECOG 1. Weight: 68 kg (down 2 kg).',
        'diagnosis': 'Colorectal carcinoma Stage III – on FOLFOX chemotherapy.',
        'treatmentGiven':
            'Anti-emetics adjusted. Nutritional support advised. Next cycle in 2 weeks.',
        'nurseNotes': 'Patient tolerated session well. IV port flushed and patent. Vitals stable.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'patientId': patients[2]['userId'],
        'patientName': patients[2]['name'],
        'doctorName': doctorName,
        'visitDate': '${now.subtract(const Duration(days: 14)).day}/'
            '${now.subtract(const Duration(days: 14)).month}/'
            '${now.subtract(const Duration(days: 14)).year}',
        'visitTime': '11:00 AM',
        'chiefComplaint': 'Lump in the right breast noticed 2 weeks ago. No pain.',
        'clinicalFindings':
            '1.5 cm firm, mobile, non-tender lump in upper outer quadrant of right breast. No skin changes.',
        'diagnosis': 'Breast lump – BIRADS 3 pending biopsy confirmation.',
        'treatmentGiven': 'Core needle biopsy scheduled. Mammogram ordered.',
        'nurseNotes': 'Patient anxious about cancer diagnosis. Emotional support provided.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 14))),
      },
      {
        'patientId': patients[3]['userId'],
        'patientName': patients[3]['name'],
        'doctorName': doctorName,
        'visitDate': '${now.subtract(const Duration(days: 5)).day}/'
            '${now.subtract(const Duration(days: 5)).month}/'
            '${now.subtract(const Duration(days: 5)).year}',
        'visitTime': '02:00 PM',
        'chiefComplaint': 'Difficulty in urination and lower back pain for 6 weeks.',
        'clinicalFindings':
            'DRE: Enlarged prostate, firm in consistency. No lymphadenopathy. PSA elevated at 6.8.',
        'diagnosis': 'Prostate carcinoma suspected – awaiting biopsy results.',
        'treatmentGiven':
            'Alpha-blocker prescribed for symptom relief. Urology referral made.',
        'nurseNotes':
            'Patient informed about biopsy procedure. Follow-up in 2 weeks. BP: 140/90 – noted.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      },
      {
        'patientId': patients[4]['userId'],
        'patientName': patients[4]['name'],
        'doctorName': doctorName,
        'visitDate': '${now.subtract(const Duration(days: 3)).day}/'
            '${now.subtract(const Duration(days: 3)).month}/'
            '${now.subtract(const Duration(days: 3)).year}',
        'visitTime': '09:30 AM',
        'chiefComplaint': 'Persistent headache and vision changes for 3 weeks.',
        'clinicalFindings':
            'Fundoscopy: Papilloedema present bilaterally. Cranial nerves intact. BP: 150/95.',
        'diagnosis': 'Raised intracranial pressure – secondary metastasis suspected.',
        'treatmentGiven':
            'Urgent MRI Brain ordered. Dexamethasone started. Neurosurgery consult.',
        'nurseNotes': 'Patient admitted for observation. Vitals monitored hourly.',
        'uploadedBy': 'Medical Staff',
        'uploadedAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
    ];

    for (final s in summaries) {
      await _db.collection('consultation_summaries').add(s);
    }
  }

  // ── Doctor Notes ────────────────────────────────────────────────────────────

  Future<void> _seedDoctorNotes(
    String doctorId,
    String doctorName,
    List<Map<String, dynamic>> patients,
  ) async {
    final now = DateTime.now();
    final notes = [
      {
        'patientId': patients[0]['userId'],
        'patientName': patients[0]['name'],
        'doctorId': doctorId,
        'doctorName': doctorName,
        'appointmentId': 'SEED_APT_001',
        'notes':
            'Patient reports pelvic discomfort worsening. CA-125 levels noted. Plan: USG follow-up next week. Reassure patient – no definitive malignancy confirmed yet.',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      },
      {
        'patientId': patients[1]['userId'],
        'patientName': patients[1]['name'],
        'doctorId': doctorId,
        'doctorName': doctorName,
        'appointmentId': 'SEED_APT_002',
        'notes':
            'Cycle 2 of FOLFOX tolerated well. Grade 2 nausea – switch ondansetron to granisetron. Weight loss concerning – refer to dietitian. Check LFTs before cycle 3.',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'patientId': patients[3]['userId'],
        'patientName': patients[3]['name'],
        'doctorId': doctorId,
        'doctorName': doctorName,
        'appointmentId': 'SEED_APT_003',
        'notes':
            'PSA 6.8. DRE suspicious. Awaiting transrectal biopsy. Counsel patient about anxiety. If positive – discuss treatment options: radical prostatectomy vs radiation.',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      },
    ];

    for (final n in notes) {
      await _db.collection('doctor_notes').add(n);
    }
  }

  // ── Prescriptions ───────────────────────────────────────────────────────────

  Future<void> _seedPrescriptions(
    String doctorId,
    String doctorName,
    List<Map<String, dynamic>> patients,
  ) async {
    final now = DateTime.now();
    final prescriptions = [
      {
        'appointmentId': 'SEED_APT_001',
        'patientId': patients[0]['userId'],
        'patientName': patients[0]['name'],
        'doctorId': doctorId,
        'doctorName': doctorName,
        'medicines': [
          {
            'medicine': 'Ferrous Sulphate',
            'dosage': '200 mg',
            'duration': '30 days',
            'instructions': 'Take after meals with orange juice. Avoid tea/coffee.'
          },
          {
            'medicine': 'Folic Acid',
            'dosage': '5 mg',
            'duration': '30 days',
            'instructions': 'Once daily, morning.'
          },
          {
            'medicine': 'Mefenamic Acid',
            'dosage': '500 mg',
            'duration': '5 days',
            'instructions': 'For pain relief. Take with food. SOS.'
          },
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      },
      {
        'appointmentId': 'SEED_APT_002',
        'patientId': patients[1]['userId'],
        'patientName': patients[1]['name'],
        'doctorId': doctorId,
        'doctorName': doctorName,
        'medicines': [
          {
            'medicine': 'Granisetron',
            'dosage': '1 mg',
            'duration': '5 days',
            'instructions': 'Twice daily. Take 1 hour before chemotherapy.'
          },
          {
            'medicine': 'Ondansetron',
            'dosage': '8 mg',
            'duration': '3 days',
            'instructions': 'SOS for breakthrough nausea.'
          },
          {
            'medicine': 'Pantoprazole',
            'dosage': '40 mg',
            'duration': '14 days',
            'instructions': 'Once daily, before breakfast.'
          },
          {
            'medicine': 'Multivitamin (Becosules)',
            'dosage': '1 capsule',
            'duration': '30 days',
            'instructions': 'Once daily after lunch.'
          },
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'appointmentId': 'SEED_APT_003',
        'patientId': patients[3]['userId'],
        'patientName': patients[3]['name'],
        'doctorId': doctorId,
        'doctorName': doctorName,
        'medicines': [
          {
            'medicine': 'Tamsulosin',
            'dosage': '0.4 mg',
            'duration': '30 days',
            'instructions': 'Once daily, 30 min after dinner. For urinary relief.'
          },
          {
            'medicine': 'Finasteride',
            'dosage': '5 mg',
            'duration': '90 days',
            'instructions': 'Once daily. May take 6 months to show effect.'
          },
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      },
      {
        'appointmentId': 'SEED_APT_004',
        'patientId': patients[4]['userId'],
        'patientName': patients[4]['name'],
        'doctorId': doctorId,
        'doctorName': doctorName,
        'medicines': [
          {
            'medicine': 'Dexamethasone',
            'dosage': '8 mg IV',
            'duration': '7 days',
            'instructions': 'Twice daily IV. Taper as directed by neurosurgeon.'
          },
          {
            'medicine': 'Pantoprazole',
            'dosage': '40 mg',
            'duration': '14 days',
            'instructions': 'Once daily to protect gastric mucosa during steroid therapy.'
          },
          {
            'medicine': 'Levetiracetam',
            'dosage': '500 mg',
            'duration': '30 days',
            'instructions': 'Twice daily. Prophylactic anti-epileptic.'
          },
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
    ];

    for (final p in prescriptions) {
      await _db.collection('prescriptions').add(p);
    }
  }

  // ── Notifications ───────────────────────────────────────────────────────────

  Future<void> _seedNotifications(String doctorId) async {
    final now = DateTime.now();
    final notifs = [
      {
        'recipientId': doctorId,
        'type': 'new_appointment',
        'title': 'New Appointment Booked',
        'message': 'Ananya Krishnan has booked an appointment for today at 9:00 AM.',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      },
      {
        'recipientId': doctorId,
        'type': 'new_appointment',
        'title': 'New Appointment Booked',
        'message': 'Rajesh Menon has booked an appointment for today at 10:00 AM.',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
      },
      {
        'recipientId': doctorId,
        'type': 'report_uploaded',
        'title': 'New Report Uploaded',
        'message': 'A PET-CT Scan report has been uploaded for Rajesh Menon.',
        'isRead': true,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'recipientId': doctorId,
        'type': 'new_appointment',
        'title': 'Appointment Request',
        'message': 'Deepa George has booked a consultation for Day after tomorrow at 9:00 AM.',
        'isRead': true,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      },
      {
        'recipientId': doctorId,
        'type': 'report_uploaded',
        'title': 'MRI Report Available',
        'message': 'MRI Brain report for Deepa George is ready for review.',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
      },
    ];

    for (final n in notifs) {
      await _db.collection('notifications').add(n);
    }
  }

  // ── Clear All ───────────────────────────────────────────────────────────────

  Future<void> _clearAll() async {
    setState(() {
      _loading = true;
      _log.clear();
    });
    try {
      final collections = [
        'appointments',
        'medical_reports',
        'consultation_summaries',
        'doctor_notes',
        'prescriptions',
        'notifications',
      ];

      final doctorId = AppUserSession.currentUser?.userId ?? 'D0001';

      for (final col in collections) {
        QuerySnapshot snap;
        if (col == 'notifications') {
          snap = await _db.collection(col)
              .where('recipientId', isEqualTo: doctorId)
              .get();
        } else if (['appointments', 'prescriptions', 'doctor_notes'].contains(col)) {
          snap = await _db.collection(col)
              .where('doctorId', isEqualTo: doctorId)
              .get();
        } else {
          // Reports and summaries — delete all seeded ones (patientIds P0001–P0005)
          snap = await _db.collection(col)
              .where('patientId', whereIn: ['P0001', 'P0002', 'P0003', 'P0004', 'P0005'])
              .get();
        }

        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        _addLog('🗑 Cleared $col (${snap.docs.length} docs)');
      }
      _addLog('✅ All seeded data cleared.');
    } catch (e) {
      _addLog('❌ Error during clear: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('Seed Sample Data'),
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: _green, size: 20),
                    const SizedBox(width: 8),
                    const Text('What will be seeded',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _green,
                            fontSize: 15)),
                  ]),
                  const SizedBox(height: 10),
                  ...[
                    '👥 5 realistic cancer patients',
                    '📅 12 appointments (today, upcoming, completed, cancelled)',
                    '🔬 8 medical reports (CBC, PET-CT, MRI, etc.)',
                    '📋 5 consultation visit summaries',
                    '📝 3 doctor consultation notes',
                    '💊 4 prescriptions with medicines',
                    '🔔 5 doctor notifications',
                  ].map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1A1A2E))),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Seed button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload_rounded),
                label: Text(_loading ? 'Seeding…' : 'Seed All Sample Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: _loading ? null : _seedAll,
              ),
            ),

            const SizedBox(height: 10),

            // Clear button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Clear Seeded Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _clearAll,
              ),
            ),

            const SizedBox(height: 20),

            // Log output
            if (_log.isNotEmpty) ...[
              const Text('Log',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 8,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(_log[i],
                          style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: _log[i].startsWith('❌')
                                  ? Colors.red.shade700
                                  : _log[i].startsWith('🎉')
                                      ? _green
                                      : const Color(0xFF1A1A2E))),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}