// lib/services/admin_service.dart
//
// Complete backend service for all Admin and Super Admin screens.
// Covers: user management, doctor management, appointment oversight,
// awareness content, homestay listings, community moderation,
// appointment rules, system statistics, and notifications.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_session.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

/// A user record as seen by the admin panel.
class AdminUserRecord {
  final String userId;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? email;
  final String? phone;
  final String? specialty;
  final String? profileUrl;

  const AdminUserRecord({
    required this.userId,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.email,
    this.phone,
    this.specialty,
    this.profileUrl,
  });

  factory AdminUserRecord.fromMap(String id, Map<String, dynamic> map) =>
      AdminUserRecord(
        userId: id,
        name: map['name'] ?? '',
        role: map['role'] ?? '',
        isActive: map['isActive'] ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        email: map['email'],
        phone: map['phone'],
        specialty: map['specialty'],
        profileUrl: map['profileUrl'],
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'role': role,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (specialty != null) 'specialty': specialty,
        if (profileUrl != null) 'profileUrl': profileUrl,
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// An appointment record as seen by the admin panel.
class AdminAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final String slot;
  final String status;
  final DateTime bookedAt;
  final String? cancelReason;

  const AdminAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.slot,
    required this.status,
    required this.bookedAt,
    this.cancelReason,
  });

  factory AdminAppointment.fromMap(String id, Map<String, dynamic> map) =>
      AdminAppointment(
        id: id,
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        doctorId: map['doctorId'] ?? '',
        doctorName: map['doctorName'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        slot: map['slot'] ?? '',
        status: map['status'] ?? 'Pending',
        bookedAt: (map['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        cancelReason: map['cancelReason'],
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// Awareness content item stored in Firestore.
class AwarenessItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;
  final String createdBy;

  const AwarenessItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.createdBy,
    this.imageUrl,
  });

  factory AwarenessItem.fromMap(String id, Map<String, dynamic> map) =>
      AwarenessItem(
        id: id,
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        category: map['category'] ?? 'General',
        imageUrl: map['imageUrl'],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: map['createdBy'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// A homestay listing stored in Firestore.
class HomestayItem {
  final String id;
  final String name;
  final String location;
  final String contact;
  final double lat;
  final double lng;
  final double ratePerDay;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  const HomestayItem({
    required this.id,
    required this.name,
    required this.location,
    required this.contact,
    required this.lat,
    required this.lng,
    required this.ratePerDay,
    required this.isActive,
    required this.createdAt,
    this.imageUrl,
  });

  factory HomestayItem.fromMap(String id, Map<String, dynamic> map) =>
      HomestayItem(
        id: id,
        name: map['name'] ?? '',
        location: map['location'] ?? '',
        contact: map['contact'] ?? '',
        lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
        ratePerDay: (map['ratePerDay'] as num?)?.toDouble() ?? 0.0,
        imageUrl: map['imageUrl'],
        isActive: map['isActive'] ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'location': location,
        'contact': contact,
        'lat': lat,
        'lng': lng,
        'ratePerDay': ratePerDay,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// A forum / community post as seen by admin moderation.
class AdminForumPost {
  final String id;
  final String collection; // 'forum_posts' or 'community_posts'
  final String authorId;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final int likes;
  final bool flagged;

  const AdminForumPost({
    required this.id,
    required this.collection,
    required this.authorId,
    required this.authorName,
    required this.message,
    required this.createdAt,
    required this.likes,
    required this.flagged,
  });

  factory AdminForumPost.fromMap(
          String id, String collection, Map<String, dynamic> map) =>
      AdminForumPost(
        id: id,
        collection: collection,
        authorId: map['authorId'] ?? '',
        authorName: map['authorName'] ?? 'Anonymous',
        message: map['message'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        likes: map['likes'] ?? 0,
        flagged: map['flagged'] ?? false,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// Appointment rule settings stored in Firestore.
class AppointmentRuleSettings {
  final int maxPerDay;
  final int slotDurationMinutes;
  final String startTime; // 'HH:mm'
  final String endTime;   // 'HH:mm'
  final String? breakStart;
  final String? breakEnd;

  const AppointmentRuleSettings({
    this.maxPerDay = 20,
    this.slotDurationMinutes = 30,
    this.startTime = '09:00',
    this.endTime = '17:00',
    this.breakStart,
    this.breakEnd,
  });

  factory AppointmentRuleSettings.fromMap(Map<String, dynamic> map) =>
      AppointmentRuleSettings(
        maxPerDay: map['maxPerDay'] as int? ?? 20,
        slotDurationMinutes: map['slotDurationMinutes'] as int? ?? 30,
        startTime: map['startTime'] ?? '09:00',
        endTime: map['endTime'] ?? '17:00',
        breakStart: map['breakStart'],
        breakEnd: map['breakEnd'],
      );

  Map<String, dynamic> toMap() => {
        'maxPerDay': maxPerDay,
        'slotDurationMinutes': slotDurationMinutes,
        'startTime': startTime,
        'endTime': endTime,
        if (breakStart != null) 'breakStart': breakStart,
        if (breakEnd != null) 'breakEnd': breakEnd,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// System-wide dashboard statistics for the admin panel.
class AdminDashboardStats {
  final int totalUsers;
  final int totalDoctors;
  final int totalPatients;
  final int totalStaff;
  final int totalAppointments;
  final int pendingAppointments;
  final int completedAppointments;
  final int todayAppointments;
  final int totalAwareness;
  final int totalHomestays;
  final int totalForumPosts;

  const AdminDashboardStats({
    this.totalUsers = 0,
    this.totalDoctors = 0,
    this.totalPatients = 0,
    this.totalStaff = 0,
    this.totalAppointments = 0,
    this.pendingAppointments = 0,
    this.completedAppointments = 0,
    this.todayAppointments = 0,
    this.totalAwareness = 0,
    this.totalHomestays = 0,
    this.totalForumPosts = 0,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// AdminService — singleton backend layer for all admin / super-admin screens
// ═══════════════════════════════════════════════════════════════════════════════

class AdminService {
  static final AdminService _instance = AdminService._();
  factory AdminService() => _instance;
  AdminService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Identity ────────────────────────────────────────────────────────────
  String get _adminId => AppUserSession.currentUser?.userId ?? '';
  String get _adminName => AppUserSession.currentUser?.name ?? 'Admin';

  // ── Collection refs ─────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _awareness =>
      _db.collection('awareness_content');
  CollectionReference<Map<String, dynamic>> get _homestays =>
      _db.collection('homestays');
  CollectionReference<Map<String, dynamic>> get _forum =>
      _db.collection('forum_posts');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _settings =>
      _db.collection('settings');

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<void> _notify({
    required String recipientId,
    required String type,
    required String title,
    required String message,
  }) async {
    await _notifications.add({
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of ALL users, sorted by createdAt.
  Stream<List<AdminUserRecord>> allUsersStream() {
    return _users.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AdminUserRecord.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// Live stream of users filtered by role.
  Stream<List<AdminUserRecord>> usersByRoleStream(String role) {
    return _users.where('role', isEqualTo: role).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AdminUserRecord.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// One-shot fetch of all users filtered by role.
  Future<List<AdminUserRecord>> getUsersByRole(String role) async {
    final snap = await _users.where('role', isEqualTo: role).get();
    final list =
        snap.docs.map((d) => AdminUserRecord.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Fetch a single user record by ID.
  Future<AdminUserRecord?> fetchUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return AdminUserRecord.fromMap(doc.id, doc.data()!);
  }

  /// Toggle a user's isActive status. Notifies the user if deactivated.
  Future<void> toggleUserActive(String userId, bool currentlyActive) async {
    await _users.doc(userId).update({'isActive': !currentlyActive});

    if (currentlyActive) {
      // Deactivated — notify user
      await _notify(
        recipientId: userId,
        type: 'account_deactivated',
        title: 'Account Deactivated',
        message:
            'Your account has been temporarily deactivated. Please contact your administrator.',
      );
    } else {
      // Reactivated — notify user
      await _notify(
        recipientId: userId,
        type: 'account_activated',
        title: 'Account Activated',
        message: 'Your account has been reactivated. You can now log in.',
      );
    }
  }

  /// Update a doctor's specialty field.
  Future<void> updateDoctorSpecialty(String userId, String specialty) async {
    await _users.doc(userId).update({
      'specialty': specialty.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update any arbitrary set of fields on a user document.
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) async {
    await _users.doc(userId).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a user record permanently (Super Admin only).
  Future<void> deleteUser(String userId) async {
    await _users.doc(userId).delete();
  }

  /// Search users by name, userId, email, or phone (client-side filter).
  Stream<List<AdminUserRecord>> searchUsersStream(String query) {
    return allUsersStream().map((users) {
      if (query.trim().isEmpty) return users;
      final lower = query.toLowerCase();
      return users
          .where((u) =>
              u.name.toLowerCase().contains(lower) ||
              u.userId.toLowerCase().contains(lower) ||
              (u.email?.toLowerCase().contains(lower) ?? false) ||
              (u.phone?.contains(lower) ?? false))
          .toList();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPOINTMENT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of ALL appointments across all doctors, sorted by date desc.
  Stream<List<AdminAppointment>> allAppointmentsStream() {
    return _appointments.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AdminAppointment.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Live stream of appointments filtered by status.
  Stream<List<AdminAppointment>> appointmentsByStatusStream(String status) {
    return _appointments
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AdminAppointment.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Live stream — today's appointments across all doctors.
  Stream<List<AdminAppointment>> todayAppointmentsStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _appointments
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AdminAppointment.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  /// Live stream — appointments for a specific doctor.
  Stream<List<AdminAppointment>> appointmentsForDoctorStream(String doctorId) {
    return _appointments
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AdminAppointment.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Live stream — appointments for a specific patient.
  Stream<List<AdminAppointment>> appointmentsForPatientStream(
      String patientId) {
    return _appointments
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AdminAppointment.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Cancel an appointment (admin override) and notify both parties.
  Future<void> cancelAppointment(
    String appointmentId, {
    String? reason,
  }) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final data = doc.data()!;

    await _appointments.doc(appointmentId).update({
      'status': 'Cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': _adminId,
      if (reason != null) 'cancelReason': reason,
    });

    final patientId = data['patientId'] as String? ?? '';
    final doctorId = data['doctorId'] as String? ?? '';
    final date = (data['date'] as Timestamp?)?.toDate();
    final slot = data['slot'] as String? ?? '';
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : 'the scheduled date';

    if (patientId.isNotEmpty) {
      await _notify(
        recipientId: patientId,
        type: 'cancellation',
        title: 'Appointment Cancelled',
        message:
            'Your appointment on $dateStr at $slot has been cancelled by the administrator.'
            '${reason != null ? ' Reason: $reason' : ''}',
      );
    }
    if (doctorId.isNotEmpty) {
      await _notify(
        recipientId: doctorId,
        type: 'cancellation',
        title: 'Appointment Cancelled by Admin',
        message:
            'An appointment on $dateStr at $slot has been cancelled by the administrator.',
      );
    }
  }

  /// Update appointment status (admin override).
  Future<void> updateAppointmentStatus(
      String appointmentId, String newStatus) async {
    await _appointments.doc(appointmentId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _adminId,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPOINTMENT RULES (global settings)
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _rulesDocId = 'appointment_rules';

  /// Fetch the global appointment rules.
  Future<AppointmentRuleSettings> fetchAppointmentRules() async {
    final doc = await _settings.doc(_rulesDocId).get();
    if (!doc.exists) return const AppointmentRuleSettings();
    return AppointmentRuleSettings.fromMap(doc.data()!);
  }

  /// Live stream of appointment rules.
  Stream<AppointmentRuleSettings> appointmentRulesStream() {
    return _settings.doc(_rulesDocId).snapshots().map((doc) {
      if (!doc.exists) return const AppointmentRuleSettings();
      return AppointmentRuleSettings.fromMap(doc.data()!);
    });
  }

  /// Save (upsert) the global appointment rules.
  Future<void> saveAppointmentRules(AppointmentRuleSettings rules) async {
    await _settings
        .doc(_rulesDocId)
        .set(rules.toMap(), SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AWARENESS CONTENT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of all awareness content, newest first.
  Stream<List<AwarenessItem>> awarenessStream() {
    return _awareness.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AwarenessItem.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Live stream filtered by category.
  Stream<List<AwarenessItem>> awarenessByCategoryStream(String category) {
    return _awareness
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AwarenessItem.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Create a new awareness content item.
  Future<String> createAwarenessItem({
    required String title,
    required String description,
    required String category,
    String? imageUrl,
  }) async {
    final ref = await _awareness.add({
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'createdBy': _adminName,
      'createdAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return ref.id;
  }

  /// Update an existing awareness item.
  Future<void> updateAwarenessItem(
    String itemId, {
    String? title,
    String? description,
    String? category,
    String? imageUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _adminName,
    };
    if (title != null) updates['title'] = title.trim();
    if (description != null) updates['description'] = description.trim();
    if (category != null) updates['category'] = category.trim();
    if (imageUrl != null) updates['imageUrl'] = imageUrl;

    await _awareness.doc(itemId).update(updates);
  }

  /// Delete an awareness item permanently.
  Future<void> deleteAwarenessItem(String itemId) async {
    await _awareness.doc(itemId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOMESTAY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of all homestay listings, newest first.
  Stream<List<HomestayItem>> homestaysStream() {
    return _homestays.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => HomestayItem.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Live stream of only active homestays.
  Stream<List<HomestayItem>> activeHomestaysStream() {
    return _homestays.where('isActive', isEqualTo: true).snapshots().map(
        (snap) => snap.docs
            .map((d) => HomestayItem.fromMap(d.id, d.data()))
            .toList());
  }

  /// Create a new homestay listing.
  Future<String> createHomestay({
    required String name,
    required String location,
    required String contact,
    required double lat,
    required double lng,
    required double ratePerDay,
    String? imageUrl,
  }) async {
    final ref = await _homestays.add({
      'name': name.trim(),
      'location': location.trim(),
      'contact': contact.trim(),
      'lat': lat,
      'lng': lng,
      'ratePerDay': ratePerDay,
      'isActive': true,
      'createdBy': _adminName,
      'createdAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return ref.id;
  }

  /// Update a homestay listing.
  Future<void> updateHomestay(
    String homestayId, {
    String? name,
    String? location,
    String? contact,
    double? lat,
    double? lng,
    double? ratePerDay,
    String? imageUrl,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) updates['name'] = name.trim();
    if (location != null) updates['location'] = location.trim();
    if (contact != null) updates['contact'] = contact.trim();
    if (lat != null) updates['lat'] = lat;
    if (lng != null) updates['lng'] = lng;
    if (ratePerDay != null) updates['ratePerDay'] = ratePerDay;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (isActive != null) updates['isActive'] = isActive;

    await _homestays.doc(homestayId).update(updates);
  }

  /// Toggle a homestay's active status.
  Future<void> toggleHomestayActive(
      String homestayId, bool currentlyActive) async {
    await _homestays.doc(homestayId).update({'isActive': !currentlyActive});
  }

  /// Delete a homestay listing permanently.
  Future<void> deleteHomestay(String homestayId) async {
    await _homestays.doc(homestayId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMUNITY / FORUM MODERATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of all forum posts from forum_posts, newest first.
  Stream<List<AdminForumPost>> forumPostsStream() {
    return _forum
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdminForumPost.fromMap(d.id, 'forum_posts', d.data()))
            .toList());
  }

  /// Live stream of flagged posts only.
  Stream<List<AdminForumPost>> flaggedPostsStream() {
    return _forum
        .where('flagged', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AdminForumPost.fromMap(d.id, 'forum_posts', d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Delete a post from the forum by ID.
  Future<void> deleteForumPost(String postId) async {
    await _forum.doc(postId).delete();
  }

  /// Toggle the flagged status of a forum post.
  Future<void> toggleFlagPost(String postId, bool currentlyFlagged) async {
    await _forum.doc(postId).update({'flagged': !currentlyFlagged});
  }

  /// Send a broadcast notification to all users of a given role.
  Future<void> broadcastToRole({
    required String role,
    required String title,
    required String message,
  }) async {
    final users = await getUsersByRole(role);
    final batch = _db.batch();
    for (final user in users) {
      final ref = _notifications.doc();
      batch.set(ref, {
        'recipientId': user.userId,
        'type': 'broadcast',
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Send a notification to a specific user.
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String type = 'admin_message',
  }) async {
    await _notify(
        recipientId: userId, type: type, title: title, message: message);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD STATISTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch system-wide dashboard statistics (one-shot).
  Future<AdminDashboardStats> fetchDashboardStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Run parallel fetches
    final results = await Future.wait([
      _users.get(),
      _appointments.get(),
      _awareness.get(),
      _homestays.get(),
      _forum.get(),
      _appointments
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .get(),
    ]);

    final usersSnap = results[0];
    final apptSnap = results[1];
    final awarenessSnap = results[2];
    final homestaySnap = results[3];
    final forumSnap = results[4];
    final todaySnap = results[5];

    int doctors = 0, patients = 0, staff = 0;
    for (final doc in usersSnap.docs) {
      final role = doc.data()['role'] as String? ?? '';
      if (role == 'Doctor') doctors++;
      if (role == 'Patient') patients++;
      if (role == 'Medical Staff') staff++;
    }

    int pending = 0, completed = 0;
    for (final doc in apptSnap.docs) {
      final status = doc.data()['status'] as String? ?? '';
      if (status == 'Pending') pending++;
      if (status == 'Completed') completed++;
    }

    return AdminDashboardStats(
      totalUsers: usersSnap.docs.length,
      totalDoctors: doctors,
      totalPatients: patients,
      totalStaff: staff,
      totalAppointments: apptSnap.docs.length,
      pendingAppointments: pending,
      completedAppointments: completed,
      todayAppointments: todaySnap.docs.length,
      totalAwareness: awarenessSnap.docs.length,
      totalHomestays: homestaySnap.docs.length,
      totalForumPosts: forumSnap.docs.length,
    );
  }

  /// Live stream of appointment counts by status (for admin dashboard charts).
  Stream<Map<String, int>> appointmentCountsStream() {
    return _appointments.snapshots().map((snap) {
      final counts = <String, int>{
        'Total': snap.docs.length,
        'Pending': 0,
        'Completed': 0,
        'Cancelled': 0,
      };
      for (final doc in snap.docs) {
        final status = doc.data()['status'] as String? ?? '';
        if (counts.containsKey(status)) counts[status] = counts[status]! + 1;
      }
      return counts;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASSWORD MANAGEMENT  (calls through to AuthService logic)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate and save a new password for a user.
  /// Returns the new plain-text password.
  Future<String> resetUserPassword(String userId) async {
    final doc = await _users.doc(userId.trim().toUpperCase()).get();
    if (!doc.exists) throw Exception('User $userId not found.');
    final data = doc.data()!;
    final name = data['name'] as String? ?? '';
    final prefix =
        userId.trim().toUpperCase().isNotEmpty ? userId.trim()[0] : 'U';
    final regId =
        userId.trim().length > 1 ? userId.trim().substring(1) : userId.trim();

    final password = _generatePassword(name, regId, prefix);
    await _users.doc(userId.trim().toUpperCase()).update({'password': password});
    return password;
  }

  String _generatePassword(String name, String regId, String prefix) {
    final first = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : prefix;
    final last = regId.length >= 4 ? regId.substring(regId.length - 4) : regId;
    final rand = (DateTime.now().millisecondsSinceEpoch % 90) + 10;
    return '$first@$last$rand';
  }
}