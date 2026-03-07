// lib/services/homestay_service.dart
//
// Firestore-backed service for the patient-facing Homestay screen.
// Replaces the static HomestayData model with live Firestore data.

import 'package:cloud_firestore/cloud_firestore.dart';

class HomestayListing {
  final String id;
  final String name;
  final String location;
  final String contact;
  final double lat;
  final double lng;
  final double ratePerDay;
  final String? imageUrl;
  final bool isActive;

  const HomestayListing({
    required this.id,
    required this.name,
    required this.location,
    required this.contact,
    required this.lat,
    required this.lng,
    required this.ratePerDay,
    required this.isActive,
    this.imageUrl,
  });

  factory HomestayListing.fromMap(String id, Map<String, dynamic> map) =>
      HomestayListing(
        id: id,
        name: map['name'] ?? '',
        location: map['location'] ?? '',
        contact: map['contact'] ?? '',
        lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
        ratePerDay: (map['ratePerDay'] as num?)?.toDouble() ?? 0.0,
        imageUrl: map['imageUrl'],
        isActive: map['isActive'] ?? true,
      );
}

class HomestayService {
  static final HomestayService _instance = HomestayService._();
  factory HomestayService() => _instance;
  HomestayService._();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('homestays');

  /// Live stream of ACTIVE homestay listings only.
  Stream<List<HomestayListing>> activeListingsStream() {
    return _col.where('isActive', isEqualTo: true).snapshots().map((snap) =>
        snap.docs
            .map((d) => HomestayListing.fromMap(d.id, d.data()))
            .toList());
  }

  /// One-shot fetch of all active homestays.
  Future<List<HomestayListing>> fetchActiveListings() async {
    final snap = await _col.where('isActive', isEqualTo: true).get();
    return snap.docs
        .map((d) => HomestayListing.fromMap(d.id, d.data()))
        .toList();
  }

  /// One-shot fetch of a single homestay by ID.
  Future<HomestayListing?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return HomestayListing.fromMap(doc.id, doc.data()!);
  }
}