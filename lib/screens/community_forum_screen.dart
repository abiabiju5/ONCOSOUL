import 'package:flutter/material.dart';
import '../models/community_model.dart';

class CommunityForumScreen extends StatelessWidget {
  const CommunityForumScreen({super.key});

  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color softBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          _buildSupportBanner(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _sectionLabel('Recent Posts'),
          const SizedBox(height: 14),
          ...CommunityData.posts.asMap().entries.map((entry) =>
              _ForumPostCard(
                index: entry.key,
                user: entry.value.user,
                time: entry.value.time,
                message: entry.value.message,
                isFlagged: entry.value.isFlagged,
              )),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: deepBlue),
          ),
        ),
      ),
      centerTitle: true,
      title: const Text(
        'Community Forum',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: deepBlue,
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE8EEF8)),
      ),
    );
  }

  // ─── Support banner ───────────────────────────────────────────────────────
  Widget _buildSupportBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: deepBlue.withOpacity(0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -10,
            top: -18,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are not alone 💙',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'This community is here to support you every step of the way.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stats row ────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      _StatItem(
        label: 'Members',
        value: '${CommunityData.posts.length * 12}+',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF1565C0),
        bg: const Color(0xFFE3F2FD),
      ),
      _StatItem(
        label: 'Posts',
        value: '${CommunityData.posts.length}',
        icon: Icons.article_rounded,
        color: const Color(0xFF00695C),
        bg: const Color(0xFFE0F2F1),
      ),
      _StatItem(
        label: 'Active',
        value: 'Today',
        icon: Icons.bolt_rounded,
        color: const Color(0xFFE65100),
        bg: const Color(0xFFFFF3E0),
      ),
    ];

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      right: s == stats.last ? 0 : 10),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: s.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: s.color.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(s.icon, size: 18, color: s.color),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: s.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: s.color.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: deepBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: deepBlue,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ─── FAB ─────────────────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create post (Coming Soon)')),
        );
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: deepBlue.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'New Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Item model ──────────────────────────────────────────────────────────
class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

// ─── Forum Post Card ──────────────────────────────────────────────────────────
class _ForumPostCard extends StatelessWidget {
  final int index;
  final String user;
  final String time;
  final String message;
  final bool isFlagged;

  const _ForumPostCard({
    required this.index,
    required this.user,
    required this.time,
    required this.message,
    required this.isFlagged,
  });

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF1565C0), Color(0xFF42A5F5)],
    [Color(0xFF00695C), Color(0xFF26A69A)],
    [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    [Color(0xFF0277BD), Color(0xFF29B6F6)],
    [Color(0xFF283593), Color(0xFF5C6BC0)],
  ];

  static const List<Color> _cardAccents = [
    Color(0xFF1565C0),
    Color(0xFF00695C),
    Color(0xFF6A1B9A),
    Color(0xFF0277BD),
    Color(0xFF283593),
  ];

  String _initials() {
    final parts = user.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return user.isNotEmpty ? user[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _avatarGradients[index % _avatarGradients.length];
    final accent = _cardAccents[index % _cardAccents.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Coloured top accent bar ──────────────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            // ── Flagged strip ────────────────────────────────────────────
            if (isFlagged)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded,
                        size: 13, color: Colors.red.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Flagged for review',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF0D1B3E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 11,
                                    color: Colors.black38),
                                const SizedBox(width: 3),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Member badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withOpacity(0.12),
                              accent.withOpacity(0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accent.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Member',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0xFFF0F4FC)),
                  const SizedBox(height: 14),

                  // Message
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF374151),
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action bar — Like only
                  Row(
                    children: [
                      _LikeChip(accent: accent),
                      const Spacer(),
                      // Post number indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#${index + 1} post',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Like Chip ────────────────────────────────────────────────────────────────
class _LikeChip extends StatefulWidget {
  final Color accent;
  const _LikeChip({required this.accent});

  @override
  State<_LikeChip> createState() => _LikeChipState();
}

class _LikeChipState extends State<_LikeChip> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _liked = !_liked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _liked
              ? widget.accent.withOpacity(0.12)
              : const Color(0xFFF0F4FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _liked
                ? widget.accent.withOpacity(0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _liked
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              size: 15,
              color: _liked ? widget.accent : Colors.black45,
            ),
            const SizedBox(width: 6),
            Text(
              _liked ? 'Liked' : 'Like',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _liked ? widget.accent : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}