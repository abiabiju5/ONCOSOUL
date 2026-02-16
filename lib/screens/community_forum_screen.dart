import 'package:flutter/material.dart';
import '../models/community_model.dart';

class CommunityForumScreen extends StatelessWidget {
  const CommunityForumScreen({super.key});


  final Color deepBlue = const Color(0xFF0D47A1);
  final Color softBlue = const Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Community Forum'),
      ),

      // ================= DYNAMIC POSTS =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // SUPPORT HEADER (UNCHANGED)
          Container(
            margin: const EdgeInsets.only(bottom: 22),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: deepBlue,
                width: 2.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.volunteer_activism,
                  size: 36,
                  color: deepBlue,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'You are not alone.\nThis community is here to support you.',
                    style: TextStyle(
                      color: deepBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= POSTS LIST =================
          ...CommunityData.posts.map((post) {
            return forumPost(
              context,
              user: post.user,
              time: post.time,
              message: post.message,
              isFlagged: post.isFlagged,
            );
          }).toList(),
        ],
      ),

      // ADD POST BUTTON (UNCHANGED)
      floatingActionButton: FloatingActionButton(
        backgroundColor: deepBlue,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create post (Coming Soon)'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ================= FORUM POST CARD =================
  Widget forumPost(
    BuildContext context, {
    required String user,
    required String time,
    required String message,
    required bool isFlagged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: deepBlue,
          width: 2.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // HEADER ROW
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: softBlue,
                child: Icon(
                  Icons.volunteer_activism,
                  color: deepBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: deepBlue,
                  ),
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // MESSAGE
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),

          // ================= FLAG INDICATOR =================
          if (isFlagged)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '⚠️ Flagged for review',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 18),

          // ACTION BAR
          Row(
            children: [
              actionIcon(Icons.thumb_up_alt_outlined, 'Like'),
            ],
          ),
        ],
      ),
    );
  }

  // ================= ACTION ICON =================
  Widget actionIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: deepBlue,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: deepBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}