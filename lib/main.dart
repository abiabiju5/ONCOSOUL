import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const OncoSoulApp());
}

class OncoSoulApp extends StatefulWidget {
  const OncoSoulApp({super.key});

  @override
  State<OncoSoulApp> createState() => _OncoSoulAppState();
}

class _OncoSoulAppState extends State<OncoSoulApp> {
  // Firebase initialization future — created once and reused
  final Future<void> _initFuture = _initializeApp();

  static Future<void> _initializeApp() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AuthService().seedSuperAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OncoSoul',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      // FutureBuilder wraps the splash so Firebase is guaranteed ready
      // before any Firestore call is ever made
      home: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          // ── Still initializing ───────────────────────────────────────────
          if (snapshot.connectionState != ConnectionState.done) {
            return const _BootScreen();
          }

          // ── Initialization failed ────────────────────────────────────────
          if (snapshot.hasError) {
            return _ErrorScreen(error: snapshot.error.toString());
          }

          // ── Ready — show splash ──────────────────────────────────────────
          return const SplashScreen();
        },
      ),
    );
  }
}

// ── Minimal boot screen shown while Firebase initialises (~200–400ms) ─────────
// Matches the splash color exactly so there's zero visual flash.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F9FF), // same as SplashScreen background
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D3B7A)),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

// ── Shown only if Firebase.initializeApp() itself throws ──────────────────────
class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Color(0xFF0D3B7A)),
              const SizedBox(height: 20),
              const Text(
                'Unable to connect',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D3B7A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please check your internet connection and restart the app.\n\n$error',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}