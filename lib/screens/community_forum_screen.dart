import 'package:flutter/material.dart';
import '../services/patient_service.dart';
import '../models/app_user_session.dart';

class CommunityForumScreen extends StatefulWidget {
  const CommunityForumScreen({super.key});
  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color softBlue = Color(0xFFE3F2FD);
  final _service = PatientService();

  void _showNewPostSheet(BuildContext context) {
    final ctrl = TextEditingController();
    bool posting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Share with the community', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: deepBlue)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl, maxLines: 5, autofocus: true,
              decoration: InputDecoration(
                hintText: 'Write something supportive...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true, fillColor: const Color(0xFFF0F4FC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: deepBlue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: posting ? null : () async {
                  if (ctrl.text.trim().isEmpty) return;
                  setModalState(() => posting = true);
                  try {
                    await _service.createPost(ctrl.text);
                    if (context.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    setModalState(() => posting = false);
                  }
                },
                child: posting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Post', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              )),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<ForumPost>>(
        stream: _service.forumPostsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            children: [
              _buildSupportBanner(),
              const SizedBox(height: 24),
              _buildStatsRow(posts.length),
              const SizedBox(height: 24),
              _sectionLabel('Recent Posts'),
              const SizedBox(height: 14),
              if (posts.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    Icon(Icons.forum_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No posts yet. Be the first!', style: TextStyle(color: Colors.grey.shade500)),
                  ]),
                ))
              else
                ...posts.asMap().entries.map((e) => _ForumPostCard(index: e.key, post: e.value, service: _service)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,
      leading: Padding(padding: const EdgeInsets.only(left: 10),
        child: GestureDetector(onTap: () => Navigator.pop(context),
          child: Container(padding: const EdgeInsets.all(8), margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: deepBlue)))),
      centerTitle: true,
      title: const Text('Community Forum', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: deepBlue, letterSpacing: -0.3)),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: const Color(0xFFE8EEF8))),
    );
  }

  Widget _buildSupportBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: deepBlue.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Row(children: [
        Container(width: 56, height: 56,
          decoration: BoxDecoration(color: Colors.white.withAlpha(46), shape: BoxShape.circle),
          child: const Icon(Icons.volunteer_activism_rounded, size: 28, color: Colors.white)),
        const SizedBox(width: 16),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('You are not alone 💙', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 5),
          Text('This community is here to support you every step of the way.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
        ])),
      ]),
    );
  }

  Widget _buildStatsRow(int postCount) {
    final stats = [
      _StatItem(label: 'Members', value: '${postCount * 12}+', icon: Icons.people_alt_rounded, color: const Color(0xFF1565C0), bg: const Color(0xFFE3F2FD)),
      _StatItem(label: 'Posts', value: '$postCount', icon: Icons.article_rounded, color: const Color(0xFF00695C), bg: const Color(0xFFE0F2F1)),
      const _StatItem(label: 'Active', value: 'Today', icon: Icons.bolt_rounded, color: Color(0xFFE65100), bg: Color(0xFFFFF3E0)),
    ];
    return Row(
      children: stats.asMap().entries.map((e) => Expanded(child: Container(
        margin: EdgeInsets.only(right: e.key < stats.length - 1 ? 10 : 0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(color: e.value.bg, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: e.value.color.withAlpha(36), shape: BoxShape.circle),
            child: Icon(e.value.icon, size: 18, color: e.value.color)),
          const SizedBox(height: 8),
          Text(e.value.value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: e.value.color)),
          const SizedBox(height: 2),
          Text(e.value.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: e.value.color.withAlpha(191))),
        ]),
      ))).toList(),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: deepBlue, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: deepBlue, letterSpacing: -0.2)),
    ]);
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNewPostSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: deepBlue.withAlpha(89), blurRadius: 14, offset: const Offset(0, 5))]),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.edit_rounded, color: Colors.white, size: 18), SizedBox(width: 8),
          Text('New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}

class _StatItem {
  final String label, value; final IconData icon; final Color color, bg;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color, required this.bg});
}

class _ForumPostCard extends StatelessWidget {
  final int index;
  final ForumPost post;
  final PatientService service;
  const _ForumPostCard({required this.index, required this.post, required this.service});

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF1565C0), Color(0xFF42A5F5)], [Color(0xFF00695C), Color(0xFF26A69A)],
    [Color(0xFF6A1B9A), Color(0xFFAB47BC)], [Color(0xFF0277BD), Color(0xFF29B6F6)],
    [Color(0xFF283593), Color(0xFF5C6BC0)],
  ];
  static const List<Color> _cardAccents = [
    Color(0xFF1565C0), Color(0xFF00695C), Color(0xFF6A1B9A), Color(0xFF0277BD), Color(0xFF283593),
  ];

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 26)),
            const SizedBox(height: 16),
            const Text('Delete Post?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E))),
            const SizedBox(height: 8),
            Text('This post will be permanently removed.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await service.deletePost(post.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  String _initials() {
    final parts = post.authorName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _avatarGradients[index % _avatarGradients.length];
    final accent = _cardAccents[index % _cardAccents.length];
    final currentUserId = AppUserSession.currentUser?.userId ?? '';
    final hasLiked = post.likedBy.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: accent.withAlpha(20), blurRadius: 14, offset: const Offset(0, 5))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 4, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient, begin: Alignment.centerLeft, end: Alignment.centerRight))),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle, boxShadow: [BoxShadow(color: gradient[0].withAlpha(77), blurRadius: 8, offset: const Offset(0, 3))]),
                alignment: Alignment.center,
                child: Text(_initials(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0D1B3E))),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 11, color: Colors.black38), const SizedBox(width: 3),
                  Text(_timeAgo(post.createdAt), style: const TextStyle(fontSize: 11, color: Colors.black38)),
                ]),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withAlpha(30), accent.withAlpha(15)]),
                    borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withAlpha(51))),
                child: Text('Member', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent))),
              if (post.authorId == currentUserId) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.delete_outline_rounded, size: 15, color: Colors.red.shade400),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFF0F4FC)),
            const SizedBox(height: 14),
            Text(post.message, style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151), height: 1.65)),
            const SizedBox(height: 16),
            Row(children: [
              GestureDetector(
                onTap: () => service.toggleLike(post),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasLiked ? accent.withAlpha(30) : const Color(0xFFF0F4FC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: hasLiked ? accent.withAlpha(89) : Colors.transparent)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(hasLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                        size: 15, color: hasLiked ? accent : Colors.black45),
                    const SizedBox(width: 6),
                    Text('${post.likes}  ${hasLiked ? 'Liked' : 'Like'}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hasLiked ? accent : Colors.black45)),
                  ])),
              ),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF0F4FC), borderRadius: BorderRadius.circular(20)),
                child: Text('#${index + 1} post', style: const TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.w500))),
            ]),
          ])),
        ])),
    );
  }
}