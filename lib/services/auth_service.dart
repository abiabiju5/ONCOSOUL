import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles used across the app
class UserRole {
  static const String superAdmin = 'Super Admin';
  static const String admin = 'Admin';
  static const String doctor = 'Doctor';
  static const String medicalStaff = 'Medical Staff';
  static const String patient = 'Patient';
}

/// Prefix map for auto-generating user IDs
class RolePrefix {
  static const Map<String, String> prefixes = {
    UserRole.superAdmin: 'S',
    UserRole.admin: 'A',
    UserRole.doctor: 'D',
    UserRole.medicalStaff: 'M',
    UserRole.patient: 'P',
  };

  static String getPrefix(String role) => prefixes[role] ?? 'U';
}

/// Model representing a user stored in Firestore
class AppUser {
  final String userId;
  final String name;
  final String role;
  final String password; // stored as plain text (hash in production)
  final bool isActive;
  final DateTime createdAt;

  AppUser({
    required this.userId,
    required this.name,
    required this.role,
    required this.password,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert Firestore document to AppUser
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      password: map['password'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert AppUser to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'password': password,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? userId,
    String? name,
    String? role,
    String? password,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Result returned from login attempt
class LoginResult {
  final bool success;
  final AppUser? user;
  final String? error;

  const LoginResult.success(this.user)
      : success = true,
        error = null;

  const LoginResult.failure(this.error)
      : success = false,
        user = null;
}

/// Core authentication service — all Firestore operations live here
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection reference ──────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  // ── Seed Super Admin (call once on first launch) ──────────────────────────
  /// Creates the Super Admin account if it doesn't exist yet.
  /// Silently ignores errors so a network blip doesn't crash startup.
  Future<void> seedSuperAdmin() async {
    try {
      const superAdminId = 'S0001';
      final doc = await _usersRef.doc(superAdminId).get();
      if (!doc.exists) {
        final superAdmin = AppUser(
          userId: superAdminId,
          name: 'Super Admin',
          role: UserRole.superAdmin,
          password: 'Admin@0001',
        );
        await _usersRef.doc(superAdminId).set(superAdmin.toMap());
      }
    } catch (_) {
      // Non-fatal: if seeding fails (e.g. offline), the admin can still
      // be seeded on next launch. Don't block app startup.
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  /// Authenticates a user by userId + password.
  /// Returns [LoginResult] with user data or error message.
  Future<LoginResult> login(String userId, String password) async {
    try {
      final normalized = userId.trim().toUpperCase();
      final doc = await _usersRef.doc(normalized).get();

      if (!doc.exists) {
        return const LoginResult.failure('User ID not found.');
      }

      final user = AppUser.fromMap(doc.data()!);

      if (!user.isActive) {
        return const LoginResult.failure(
            'This account has been deactivated. Contact admin.');
      }

      if (user.password != password.trim()) {
        return const LoginResult.failure('Incorrect password.');
      }

      return LoginResult.success(user);
    } catch (e) {
      return LoginResult.failure('Login failed: ${e.toString()}');
    }
  }

  // ── CREATE USER ───────────────────────────────────────────────────────────
  /// Admin creates a new user with auto-generated credentials.
  /// Returns the created [AppUser] or throws on duplicate userId.
  Future<AppUser> createUser({
    required String name,
    required String role,
    required String registrationId,
  }) async {
    final prefix = RolePrefix.getPrefix(role);
    final userId = '$prefix$registrationId'.toUpperCase();

    // Check uniqueness
    final existing = await _usersRef.doc(userId).get();
    if (existing.exists) {
      throw Exception('User ID $userId already exists.');
    }

    final password = _generatePassword(name, registrationId, prefix);

    final user = AppUser(
      userId: userId,
      name: name.trim(),
      role: role,
      password: password,
    );

    await _usersRef.doc(userId).set(user.toMap());
    return user;
  }

  // ── RESET PASSWORD ────────────────────────────────────────────────────────
  /// Generates and saves a new password for an existing user.
  /// Returns the new password string.
  Future<String> resetPassword(String userId) async {
    final normalized = userId.trim().toUpperCase();
    final doc = await _usersRef.doc(normalized).get();

    if (!doc.exists) {
      throw Exception('User ID $normalized not found.');
    }

    final user = AppUser.fromMap(doc.data()!);
    final prefix = normalized.isNotEmpty ? normalized[0] : 'U';
    final regId = normalized.length > 1 ? normalized.substring(1) : normalized;
    final newPassword = _generatePassword(user.name, regId, prefix);

    await _usersRef.doc(normalized).update({'password': newPassword});
    return newPassword;
  }

  // ── TOGGLE ACTIVE STATUS ──────────────────────────────────────────────────
  Future<void> setUserActive(String userId, bool isActive) async {
    await _usersRef.doc(userId).update({'isActive': isActive});
  }

  // ── GET ALL USERS (stream) ────────────────────────────────────────────────
  /// Returns a real-time stream of all users, sorted by createdAt.
  Stream<List<AppUser>> getAllUsersStream() {
    return _usersRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppUser.fromMap(d.data())).toList());
  }

  /// Returns a one-time list of all users (non-stream).
  Future<List<AppUser>> getAllUsers() async {
    final snap =
        await _usersRef.orderBy('createdAt', descending: false).get();
    return snap.docs.map((d) => AppUser.fromMap(d.data())).toList();
  }

  // ── SEARCH / FILTER ───────────────────────────────────────────────────────
  Future<List<AppUser>> getUsersByRole(String role) async {
    final snap = await _usersRef.where('role', isEqualTo: role).get();
    return snap.docs.map((d) => AppUser.fromMap(d.data())).toList();
  }

  // ── PASSWORD GENERATOR ────────────────────────────────────────────────────
  /// Format: FirstLetter@Last4DigitsOfRegId + 2-digit random
  String _generatePassword(String name, String regId, String prefix) {
    final firstLetter =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : prefix;
    final lastFour =
        regId.length >= 4 ? regId.substring(regId.length - 4) : regId;
    final random = (DateTime.now().millisecondsSinceEpoch % 90) + 10;
    return '$firstLetter@$lastFour$random';
  }
}