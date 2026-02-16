import 'package:flutter/material.dart';//inside medical staff

class UploadMedicalReportScreen extends StatefulWidget {
  const UploadMedicalReportScreen({super.key});

  @override
  State<UploadMedicalReportScreen> createState() =>
      _UploadMedicalReportScreenState();
}

class _UploadMedicalReportScreenState
    extends State<UploadMedicalReportScreen> {
  final Color deepBlue = const Color(0xFF0D47A1);

  final TextEditingController patientIdController =
      TextEditingController();
  final TextEditingController labNameController =
      TextEditingController();

  String selectedReportType = 'Blood Test';
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text('Upload Medical Report'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle('Patient Information'),
            const SizedBox(height: 8),

            inputField(
              controller: patientIdController,
              label: 'Patient ID',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 20),
            sectionTitle('Report Details'),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedReportType,
              decoration: inputDecoration('Report Type'),
              items: const [
                DropdownMenuItem(
                  value: 'Blood Test',
                  child: Text('Blood Test'),
                ),
                DropdownMenuItem(
                  value: 'CT Scan',
                  child: Text('CT Scan'),
                ),
                DropdownMenuItem(
                  value: 'MRI Scan',
                  child: Text('MRI Scan'),
                ),
                DropdownMenuItem(
                  value: 'Biopsy',
                  child: Text('Biopsy'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedReportType = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            inputField(
              controller: labNameController,
              label: 'Lab / Hospital Name',
              icon: Icons.local_hospital_outlined,
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: boxDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined),
                    const SizedBox(width: 10),
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            sectionTitle('Upload File'),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('File picker (UI only)'),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose Report File'),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepBlue,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: () {
                  if (patientIdController.text.isEmpty ||
                      labNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please fill all required fields'),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Medical report uploaded successfully'),
                    ),
                  );

                  Navigator.pop(context);
                },
                child: const Text(
                  'Submit Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 UI HELPERS

  Widget sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: deepBlue,
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: inputDecoration(label).copyWith(
        prefixIcon: Icon(icon),
      ),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  BoxDecoration boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: deepBlue.withValues(alpha:0.3),
      ),
    );
  }
}