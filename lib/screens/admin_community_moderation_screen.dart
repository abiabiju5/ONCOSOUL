import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminCommunityModerationScreen extends StatefulWidget {
  const AdminCommunityModerationScreen({super.key});

  @override
  State<AdminCommunityModerationScreen> createState() =>
      _AdminCommunityModerationScreenState();
}

class _AdminCommunityModerationScreenState
    extends State<AdminCommunityModerationScreen>
    with SingleTickerProviderStateMixin {
  static const Color _deepBlue = Color(0xFF0D47A1);
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deletePost(String docId, String collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Colors.red)),
        content: const Text(
            'Are you sure you want to permanently delete this post?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Post deleted.'),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _toggleFlag(
      String docId, String collection, bool currentFlag) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .update({'flagged': !currentFlag});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(currentFlag ? 'Post unflagged.' : 'Post flagged for review.'),
      backgroundColor:
          currentFlag ? Colors.green.shade700 : Colors.orange.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        title: const Text('Community Moderation',
            style:
                TextStyle(fontWeight: FontWeight.w700, color: _deepBlue)),
        backgroundColor: Colors.white,
        foregroundColor: _deepBlue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _deepBlue,
          labelColor: _deepBlue,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'All Posts'),
            Tab(text: 'Flagged'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search posts...',
                prefixIcon:
                    const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F7FF),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFDDE3F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFDDE3F0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _deepBlue, width: 1.5)),
              ),
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsList(flaggedOnly: false),
                _buildPostsList(flaggedOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList({required bool flaggedOnly}) {
    // Single query with no compound filter — filter flagged client-side
    // to avoid needing a Firestore composite index
    final Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('forum_posts')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Client-side flagged filter
          if (flaggedOnly) {
            final flagged = data['flagged'] ?? false;
            if (flagged != true) return false;
          }
          if (_searchQuery.isEmpty) return true;
          final content =
              (data['message'] ?? '').toString().toLowerCase();
          final author =
              (data['authorName'] ?? '').toString().toLowerCase();
          return content.contains(_searchQuery) ||
              author.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined,
                    size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                    flaggedOnly
                        ? 'No flagged posts'
                        : 'No posts found',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final docId = docs[i].id;
            final author = data['authorName'] ?? 'Anonymous';
            final content = data['message'] ?? '';
            final isFlagged = data['flagged'] ?? false;
            final timestamp = data['createdAt'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('dd MMM yyyy, hh:mm a')
                    .format(timestamp.toDate())
                : 'Unknown time';
            final likesCount = data['likes'] ?? 0;
            final likedBy = List<String>.from(data['likedBy'] ?? []);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isFlagged
                    ? Border.all(
                        color: Colors.orange.shade300, width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              _deepBlue.withValues(alpha: 0.1),
                          child: Text(
                            author.isNotEmpty
                                ? author[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: _deepBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(author,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(formattedDate,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black38)),
                            ],
                          ),
                        ),
                        if (isFlagged)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.orange.shade300),
                            ),
                            child: Text('Flagged',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Content
                    Text(content,
                        style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF1A1A2E),
                            height: 1.5)),
                    const SizedBox(height: 10),
                    // Stats
                    Row(
                      children: [
                        Icon(Icons.favorite_border,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text('$likesCount',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                        const SizedBox(width: 12),
                        Icon(Icons.people_outline,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text('${likedBy.length} liked',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                        const Spacer(),
                        // Flag button
                        GestureDetector(
                          onTap: () => _toggleFlag(
                              docId, 'forum_posts', isFlagged),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isFlagged
                                  ? Colors.orange.shade50
                                  : const Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isFlagged
                                      ? Colors.orange.shade300
                                      : const Color(0xFFDDE3F0)),
                            ),
                            child: Icon(
                              isFlagged
                                  ? Icons.flag
                                  : Icons.flag_outlined,
                              size: 16,
                              color: isFlagged
                                  ? Colors.orange.shade700
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        GestureDetector(
                          onTap: () =>
                              _deletePost(docId, 'forum_posts'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.shade200),
                            ),
                            child: Icon(Icons.delete_outline,
                                size: 16,
                                color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}