import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AwarenessScreen extends StatefulWidget {
  const AwarenessScreen({super.key});

  @override
  State<AwarenessScreen> createState() => _AwarenessScreenState();
}

class _AwarenessScreenState extends State<AwarenessScreen> {
  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);

  String _selectedCategory = 'All';
  String _searchQuery = '';

  final _collection = FirebaseFirestore.instance
      .collection('awareness_content')
      .orderBy('createdAt', descending: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        backgroundColor: deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Awareness & Education',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _collection.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}',
                style: const TextStyle(color: Colors.red)));
          }
          final docs = snap.data?.docs ?? [];
          final allItems = docs.map((d) => d.data() as Map<String, dynamic>).toList();

          final categories = [
            'All',
            ...allItems
                .map((e) => e['category'] as String? ?? '')
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList()
              ..sort()
          ];

          final filtered = allItems.where((e) {
            final matchCat = _selectedCategory == 'All' ||
                e['category'] == _selectedCategory;
            final matchSearch = _searchQuery.isEmpty ||
                (e['title'] ?? '').toString().toLowerCase().contains(_searchQuery);
            return matchCat && matchSearch;
          }).toList();

          return Column(children: [
            // Search + filter bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search articles...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FF),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE3F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE3F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: deepBlue, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected ? deepBlue : lightBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(cat,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : deepBlue)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
            ),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.article_outlined, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No articles found',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                      ]),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final imageUrl = (item['imageUrl'] ?? '').toString().trim();
                        return GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => AwarenessDetailScreen(data: item))),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(children: [
                              // Image with loading + error states
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(14)),
                                child: _NetworkImage(
                                  url: imageUrl,
                                  width: 80,
                                  height: 80,
                                  placeholder: _imagePlaceholder(),
                                ),
                              ),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: lightBlue,
                                          borderRadius: BorderRadius.circular(6)),
                                      child: Text(item['category'] ?? '',
                                          style: const TextStyle(
                                              color: deepBlue,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(item['title'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Color(0xFF1A1A2E))),
                                    const SizedBox(height: 4),
                                    Text(item['description'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500)),
                                  ]),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.grey),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80, height: 80, color: lightBlue,
      child: const Icon(Icons.article_rounded, color: deepBlue, size: 32),
    );
  }
}

// ── Reusable network image widget with loading + error state ─────────────────
class _NetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final Widget placeholder;

  const _NetworkImage({
    required this.url,
    required this.width,
    required this.height,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // Show spinner while loading
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width, height: height,
          child: const Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2,
                  color: Color(0xFF0D47A1)),
            ),
          ),
        );
      },
      // Show placeholder on error (broken URL, expired token, etc.)
      errorBuilder: (_, error, __) => placeholder,
    );
  }
}

// ── Detail Screen ─────────────────────────────────────────────────────────────
class AwarenessDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const AwarenessDetailScreen({super.key, required this.data});

  static const Color deepBlue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        title: Text(data['title'] ?? '',
            style: const TextStyle(
                color: deepBlue, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: deepBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _NetworkImage(
                url: imageUrl,
                width: double.infinity,
                height: 200,
                placeholder: Container(
                  width: double.infinity, height: 200,
                  color: const Color(0xFFE3F2FD),
                  child: const Icon(Icons.article_rounded,
                      color: deepBlue, size: 48),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8)),
            child: Text(data['category'] ?? '',
                style: const TextStyle(
                    color: deepBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          Text(data['title'] ?? '',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Text(data['description'] ?? '',
              style: const TextStyle(
                  fontSize: 15, height: 1.6, color: Color(0xFF444444))),
        ]),
      ),
    );
  }
}