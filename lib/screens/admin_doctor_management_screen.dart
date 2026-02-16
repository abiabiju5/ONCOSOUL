import 'package:flutter/material.dart';

class AdminDoctorManagementScreen extends StatefulWidget {
  const AdminDoctorManagementScreen({super.key});

  @override
  State<AdminDoctorManagementScreen> createState() =>
      _AdminDoctorManagementScreenState();
}

class _AdminDoctorManagementScreenState
    extends State<AdminDoctorManagementScreen> {
  final Color deepBlue = const Color(0xFF0D47A1);

  // Dummy doctor list (UI only)
  final List<Map<String, dynamic>> doctors = [
    {
      'name': 'Dr. Anita Sharma',
      'specialization': 'Oncologist',
      'available': true,
    },
    {
      'name': 'Dr. Rahul Verma',
      'specialization': 'Radiologist',
      'available': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Doctor Management'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: deepBlue,
        onPressed: () {
          showAddDoctorDialog();
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return doctorCard(doctor, index);
        },
      ),
    );
  }

  // ================= DOCTOR CARD =================
  Widget doctorCard(Map<String, dynamic> doctor, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: deepBlue.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: deepBlue.withValues(alpha:0.1),
                child: Icon(Icons.medical_services, color: deepBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: deepBlue,
                      ),
                    ),
                    Text(
                      doctor['specialization'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                doctor['available']
                    ? 'Available for Appointments'
                    : 'Not Available',
                style: TextStyle(
                  color: doctor['available']
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: doctor['available'],
                activeColor: deepBlue,
                onChanged: (value) {
                  setState(() {
                    doctors[index]['available'] = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= ADD DOCTOR DIALOG =================
  void showAddDoctorDialog() {
    final TextEditingController nameController =
        TextEditingController();
    final TextEditingController specController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Doctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: specController,
              decoration: const InputDecoration(
                labelText: 'Specialization',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: deepBlue,
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  specController.text.isNotEmpty) {
                setState(() {
                  doctors.add({
                    'name': nameController.text,
                    'specialization': specController.text,
                    'available': true,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}