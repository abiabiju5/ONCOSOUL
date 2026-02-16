import 'package:flutter/material.dart';
import 'screens/super_admin_dashboard.dart';
import 'patient_dashboard.dart';
import 'doctor_dashboard.dart';
import 'admin_dashboard.dart';
import 'models/user_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {

  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool isLoading = false;
  bool obscurePassword = true;

  final Color deepBlue = const Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  // ================= LOGIN LOGIC =================
  void handleLogin() async {
    String id = idController.text.trim().toUpperCase();
    String password = passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter ID and Password')),
      );
      return;
    }

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    final user = UserData.findUser(id);

    setState(() => isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    if (!user.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account is deactivated')),
      );
      return;
    }

    // ================= ROLE NAVIGATION =================

    if (user.role == 'Patient') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PatientDashboard(userName: user.name),
        ),
      );
    }

    else if (user.role == 'Doctor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DoctorDashboard(),
        ),
      );
    }

    else if (user.role == 'Medical Staff') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(role: 'medical'),
        ),
      );
    }

    else if (user.role == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(role: 'admin'),
        ),
      );
    }

    else if (user.role == 'Super Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SuperAdminDashboard(),
        ),
      );
    }
  }

  InputDecoration inputStyle(
      String label,
      IconData icon,
      Widget? suffix) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: deepBlue),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F8FF),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: SizedBox(
                    width: 340,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade50,
                          ),
                          child: Icon(
                            Icons.volunteer_activism,
                            size: 60,
                            color: deepBlue,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'OncoSoul',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: deepBlue,
                          ),
                        ),

                        const SizedBox(height: 30),

                        TextField(
                          controller: idController,
                          decoration: inputStyle(
                            'User ID',
                            Icons.person_outline,
                            null,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: inputStyle(
                            'Password',
                            Icons.lock_outline,
                            IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: deepBlue,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed:
                                isLoading ? null : handleLogin,
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      letterSpacing: 1,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}