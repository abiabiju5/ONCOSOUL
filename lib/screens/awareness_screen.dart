import 'package:flutter/material.dart';
import '../models/awareness_model.dart';

class AwarenessScreen extends StatefulWidget {
  const AwarenessScreen({super.key});

  @override
  State<AwarenessScreen> createState() =>
      _AwarenessScreenState();
}

class _AwarenessScreenState
    extends State<AwarenessScreen> {

  final Color deepBlue = const Color(0xFF0D47A1);

  String selectedCategory = 'All';
  String searchQuery = '';

  List<String> get categories {
    final uniqueCategories = AwarenessData.contents
        .map((e) => e.category)
        .toSet()
        .toList();
    return ['All', ...uniqueCategories];
  }

  @override
  Widget build(BuildContext context) {

    final filteredList = AwarenessData.contents.where((content) {

      final matchesCategory =
          selectedCategory == 'All' ||
              content.category == selectedCategory;

      final matchesSearch =
          content.title.toLowerCase().contains(
              searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;

    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Awareness & Education'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ================= SEARCH =================
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search articles...',
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // ================= CATEGORY FILTER =================
            DropdownButtonFormField(
  initialValue: selectedCategory,
  items: categories.map((category) {
    return DropdownMenuItem(
      value: category,
      child: Text(category),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedCategory = value!;
    });

              },
              decoration: const InputDecoration(
                labelText: 'Filter by Category',
              ),
            ),

            const SizedBox(height: 20),

            // ================= LIST =================
            Expanded(
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {

                  final content =
                      filteredList[index];

                  return awarenessCard(content);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget awarenessCard(AwarenessContent content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF34495E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            content.imagePath,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          content.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          content.category,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white70,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AwarenessDetailScreen(content: content),
            ),
          );
        },
      ),
    );
  }
}

class AwarenessDetailScreen extends StatelessWidget {
  final AwarenessContent content;

  const AwarenessDetailScreen({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(content.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(content.imagePath),
            const SizedBox(height: 16),
            Text(
              content.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}