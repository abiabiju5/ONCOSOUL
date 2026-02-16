import 'package:flutter/material.dart';
import '../models/community_model.dart';

class AdminCommunityModerationScreen extends StatefulWidget {
  const AdminCommunityModerationScreen({super.key});

  @override
  State<AdminCommunityModerationScreen> createState() =>
      _AdminCommunityModerationScreenState();
}

class _AdminCommunityModerationScreenState
    extends State<AdminCommunityModerationScreen> {

  final Color deepBlue = const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Moderation'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: CommunityData.posts.length,
        itemBuilder: (context, index) {
          final post = CommunityData.posts[index];

          return Card(
            child: ListTile(
              title: Text(post.user),
              subtitle: Text(post.message),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'flag') {
                    setState(() {
                      post.isFlagged = true;
                    });
                  }
                  if (value == 'delete') {
                    setState(() {
                      CommunityData.posts.removeAt(index);
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'flag',
                    child: Text('Flag Post'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete Post',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}