class AwarenessContent {
  final String title;
  final String description;
  final String category;
  final String imagePath;

  AwarenessContent({
    required this.title,
    required this.description,
    required this.category,
    required this.imagePath,
  });
}

class AwarenessData {
  static List<AwarenessContent> contents = [
    AwarenessContent(
      title: 'Cancer Basics',
      description:
          'Cancer occurs when abnormal cells grow uncontrollably. Early detection improves survival rates.',
      category: 'Basics',
      imagePath: 'assets/images/awareness1.jpg',
    ),
    AwarenessContent(
      title: 'Treatment & Care',
      description:
          'Treatment includes chemotherapy, radiation, surgery and targeted therapy.',
      category: 'Treatment',
      imagePath: 'assets/images/awareness2.jpg',
    ),
    AwarenessContent(
      title: 'Nutrition & Lifestyle',
      description:
          'Balanced diet, hydration and light physical activity support recovery.',
      category: 'Lifestyle',
      imagePath: 'assets/images/awareness3.jpg',
    ),
  ];
}