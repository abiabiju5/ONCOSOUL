import 'package:flutter/material.dart';
import 'dart:math';

class AdminUserAccountScreen extends StatefulWidget {
  const AdminUserAccountScreen({super.key});

  @override
  State<AdminUserAccountScreen> createState() =>
      _AdminUserAccountScreenState();
}

class _AdminUserAccountScreenState
    extends State<AdminUserAccountScreen> {
  String selectedRole = 'Patient';

  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController regIdController =
      TextEditingController();

  String generatedUserId = '';
  String generatedPassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create User Account')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(
                    value: 'Patient', child: Text('Patient')),
                DropdownMenuItem(
                    value: 'Medical Staff',
                    child: Text('Medical Staff')),
                DropdownMenuItem(
                    value: 'Doctor', child: Text('Doctor')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
              decoration:
                  const InputDecoration(labelText: 'User Role'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: regIdController,
              decoration: const InputDecoration(
                  labelText: 'Registration ID'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: generateCredentials,
                child: const Text('Generate Credentials'),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Generated User ID',
                hintText: generatedUserId,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: generatedPassword,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void generateCredentials() {
    if (nameController.text.isEmpty ||
        regIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter Name and Registration ID')),
      );
      return;
    }

    final regId = regIdController.text.trim();
    final rolePrefix = selectedRole == 'Patient'
        ? 'P'
        : selectedRole == 'Medical Staff'
            ? 'M'
            : 'D';

    // 🔹 USER ID = PREFIX + REG ID
    generatedUserId = '$rolePrefix$regId';

    // 🔹 PASSWORD GENERATION
    final lastFour =
        regId.length >= 4 ? regId.substring(regId.length - 4) : regId;

    final firstLetter =
        nameController.text.trim()[0].toUpperCase();

    final randomTwoDigits =
        Random().nextInt(90) + 10; // 10–99

    generatedPassword =
        '$firstLetter@$lastFour$randomTwoDigits';

    setState(() {});
  }
}