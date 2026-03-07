// lib/services/awareness_service.dart
//
// Firestore-backed service for the patient-facing Awareness screen.
// Replaces the static AwarenessData model with live Firestore data.

import 'package:cloud_firestore/cloud_firestore.dart';

class AwarenessFirestoreItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;

  const AwarenessFirestoreItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    this.imageUrl,
  });

  factory AwarenessFirestoreItem.fromMap(
          String id, Map<String, dynamic> map) =>
      AwarenessFirestoreItem(
        id: id,
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        category: map['category'] ?? 'General',
        imageUrl: map['imageUrl'],
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class AwarenessService {
  static final AwarenessService _instance = AwarenessService._();
  factory AwarenessService() => _instance;
  AwarenessService._();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('awareness_content');

  /// Live stream of ALL awareness items, newest first.
  Stream<List<AwarenessFirestoreItem>> allItemsStream() {
    return _col.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AwarenessFirestoreItem.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Live stream filtered by category.
  Stream<List<AwarenessFirestoreItem>> itemsByCategoryStream(
      String category) {
    return _col.where('category', isEqualTo: category).snapshots().map(
        (snap) {
      final list = snap.docs
          .map((d) => AwarenessFirestoreItem.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// One-shot fetch of all awareness items.
  Future<List<AwarenessFirestoreItem>> fetchAllItems() async {
    final snap = await _col.get();
    final list = snap.docs
        .map((d) => AwarenessFirestoreItem.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// One-shot fetch of distinct categories.
  Future<List<String>> fetchCategories() async {
    final items = await fetchAllItems();
    final cats = items.map((i) => i.category).toSet().toList()..sort();
    return cats;
  }
}