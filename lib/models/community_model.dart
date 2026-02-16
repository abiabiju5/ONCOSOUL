class CommunityPost {
  final String user;
  final String message;
  final String time;
  bool isFlagged;

  CommunityPost({
    required this.user,
    required this.message,
    required this.time,
    this.isFlagged = false,
  });
}

class CommunityData {
  static List<CommunityPost> posts = [
    CommunityPost(
      user: 'Ananya R.',
      message:
          'I was diagnosed with cancer, but I am staying strong.',
      time: '2 hours ago',
    ),
    CommunityPost(
      user: 'Rahul K.',
      message:
          'Can someone suggest nutrition tips during radiation therapy?',
      time: 'Yesterday',
    ),
  ];
}