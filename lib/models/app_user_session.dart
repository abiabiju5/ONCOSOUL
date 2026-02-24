import 'package:cloud_firestore/cloud_firestore.dart';

// ── AppUser ───────────────────────────────────────────────────────────────────
//
// NOTE: auth_service.dart defines its own AppUser (for admin/auth operations).
// To avoid the ambiguous_import error wherever both are imported, use:
//
//   import 'package:oncosoul/models/app_user_session.dart' hide AppUser;
//   import 'package:oncosoul/services/auth_service.dart';

class AppUser {
  final String userId;
  final String name;
  final String email;
  final String role;        // matches UserRole constants in auth_service.dart
  final bool isActive;
  final String? phone;
  final String? specialty;  // doctors only
  final String? profileUrl;

  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.phone,
    this.specialty,
    this.profileUrl,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        userId: id,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        role: map['role'] ?? 'Patient',
        isActive: map['isActive'] ?? true,
        phone: map['phone'],
        specialty: map['specialty'],
        profileUrl: map['profileUrl'],
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'email': email,
        'role': role,
        'isActive': isActive,
        if (phone != null) 'phone': phone,
        if (specialty != null) 'specialty': specialty,
        if (profileUrl != null) 'profileUrl': profileUrl,
      };

  bool get isDoctor => role == 'Doctor';
  bool get isPatient => role == 'Patient';
  bool get isStaff => role == 'Medical Staff';
  bool get isAdmin => role == 'Admin';
}

// ── AppUserSession ────────────────────────────────────────────────────────────

class AppUserSession {
  AppUserSession._();

  static AppUser? _currentUser;

  static AppUser? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  static void set(AppUser user) => _currentUser = user;

  static void fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (doc.exists && doc.data() != null) {
      _currentUser = AppUser.fromMap(doc.id, doc.data()!);
    }
  }

  static void clear() => _currentUser = null;

  static String get userId => _currentUser?.userId ?? '';
  static String get userName => _currentUser?.name ?? '';
  static String get userEmail => _currentUser?.email ?? '';
  static String get userRole => _currentUser?.role ?? '';
}