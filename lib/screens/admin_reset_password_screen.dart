import 'package:flutter/material.dart';
import 'dart:math';

class AdminResetPasswordScreen extends StatefulWidget {
  const AdminResetPasswordScreen({super.key});

  @override
  State<AdminResetPasswordScreen> createState() =>
      _AdminResetPasswordScreenState();
}

class _AdminResetPasswordScreenState
    extends State<AdminResetPasswordScreen> {
  final TextEditingController userIdController =
      TextEditingController();

  String newPassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: userIdController,
              decoration:
                  const InputDecoration(labelText: 'User ID'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: resetPassword,
                child: const Text('Generate New Password'),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: newPassword,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void resetPassword() {
    final userId = userIdController.text.trim();

    if (userId.isEmpty || userId.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid User ID')),
      );
      return;
    }

    // 🔹 Extract Role Prefix
    final prefix = userId[0];

    // 🔹 Extract Registration ID
    final regId = userId.substring(1);

    // 🔹 Get last 4 digits of Reg ID
    final lastFour =
        regId.length >= 4 ? regId.substring(regId.length - 4) : regId;

    // 🔹 Generate new random 2 digits
    final randomTwoDigits =
        Random().nextInt(90) + 10;

    newPassword = '$prefix@$lastFour$randomTwoDigits';

    setState(() {});
  }
}