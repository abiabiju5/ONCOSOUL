import 'package:flutter/material.dart';
import '../services/patient_service.dart';

class PatientPrescriptionsScreen extends StatelessWidget {
  const PatientPrescriptionsScreen({super.key});
  static const Color deepBlue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final service = PatientService();
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<PatientPrescription>>(
        stream: service.myPrescriptionsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)));
          }
          final prescriptions = snap.data ?? [];
          if (prescriptions.isEmpty) return _buildEmptyState();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (context, i) => _PrescriptionCard(prescription: prescriptions[i]),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: deepBlue)),
      ),
      centerTitle: true,
      title: const Text('My Prescriptions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: deepBlue, letterSpacing: -0.3)),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: const Color(0xFFE8EEF8))),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
        child: const Icon(Icons.medication_outlined, size: 38, color: deepBlue)),
      const SizedBox(height: 20),
      const Text('No Prescriptions Yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E))),
      const SizedBox(height: 8),
      Text('Prescriptions issued by your doctor will appear here.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
    ]));
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PatientPrescription prescription;
  const _PrescriptionCard({required this.prescription});
  static const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final dateStr = '${prescription.createdAt.day} ${monthNames[prescription.createdAt.month - 1]} ${prescription.createdAt.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF7B1FA2).withAlpha(20), blurRadius: 12, offset: const Offset(0, 4))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 4, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)]))),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.medication_rounded, color: Color(0xFF7B1FA2), size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dr. ${prescription.doctorName}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E))),
                const SizedBox(height: 2),
                Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(20)),
                child: const Text('Prescription', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7B1FA2)))),
            ]),

            // Diagnosis
            if (prescription.diagnosis != null && prescription.diagnosis!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF3E5F5).withAlpha(128), borderRadius: BorderRadius.circular(10)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.local_hospital_outlined, size: 15, color: Color(0xFF7B1FA2)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Diagnosis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7B1FA2))),
                    const SizedBox(height: 2),
                    Text(prescription.diagnosis!, style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4)),
                  ])),
                ])),
            ],

            // Medicines
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 12),
            const Text('Medicines Prescribed',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
            const SizedBox(height: 10),
            ...prescription.medicines.map((m) {
              final name = m['medicine'] ?? m['name'] ?? '';
              final dosage = m['dosage'] ?? '';
              final duration = m['duration'] ?? '';
              return Padding(padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(margin: const EdgeInsets.only(top: 5, right: 10),
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF7B1FA2), shape: BoxShape.circle)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D1B3E))),
                    if (dosage.isNotEmpty || duration.isNotEmpty)
                      Text('${dosage.isNotEmpty ? dosage : ''}${dosage.isNotEmpty && duration.isNotEmpty ? '  ·  ' : ''}${duration.isNotEmpty ? duration : ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ])),
                ]));
            }),
          ])),
        ])),
    );
  }
}