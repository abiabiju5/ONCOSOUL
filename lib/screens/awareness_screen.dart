import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Category accent colours ───────────────────────────────────────────────────
const Map<String, Color> kCatColors = {
  'Breast Cancer'   : Color(0xFFE91E8C),
  'Lung Cancer'     : Color(0xFF1565C0),
  'Skin Cancer'     : Color(0xFFE65100),
  'Cervical Cancer' : Color(0xFF6A1B9A),
  'Colon Cancer'    : Color(0xFF2E7D32),
  'Prevention'      : Color(0xFF00695C),
  'Treatment'       : Color(0xFF283593),
  'Mental Health'   : Color(0xFF4527A0),
  'Nutrition'       : Color(0xFF558B2F),
  'General'         : Color(0xFF0277BD),
};

const Color kDeepBlue = Color(0xFF0D47A1);

Color accentFor(String cat) => kCatColors[cat] ?? kDeepBlue;

const Map<String, IconData> kCatIcons = {
  'Breast Cancer'   : Icons.favorite_rounded,
  'Lung Cancer'     : Icons.air_rounded,
  'Skin Cancer'     : Icons.wb_sunny_rounded,
  'Cervical Cancer' : Icons.female_rounded,
  'Colon Cancer'    : Icons.health_and_safety_rounded,
  'Prevention'      : Icons.shield_rounded,
  'Treatment'       : Icons.medical_services_rounded,
  'Mental Health'   : Icons.psychology_rounded,
  'Nutrition'       : Icons.restaurant_rounded,
  'General'         : Icons.info_rounded,
};

IconData iconFor(String cat) => kCatIcons[cat] ?? Icons.article_rounded;

// ── Main screen ───────────────────────────────────────────────────────────────
class AwarenessScreen extends StatefulWidget {
  const AwarenessScreen({super.key});
  @override
  State<AwarenessScreen> createState() => _AwarenessScreenState();
}

class _AwarenessScreenState extends State<AwarenessScreen> {
  String? _selectedCategory; // null = home/category grid

  final _stream = FirebaseFirestore.instance
      .collection('awareness_content')
      .orderBy('createdAt', descending: false)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          final allItems = docs
              .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
              .toList();

          // Build category list from data
          final categories = allItems
              .map((e) => e['category'] as String? ?? '')
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          if (_selectedCategory == null) {
            return _CategoryHomeView(
              categories: categories,
              allItems: allItems,
              onSelectCategory: (cat) =>
                  setState(() => _selectedCategory = cat),
            );
          }

          // Filtered articles for selected category
          final filtered = allItems
              .where((e) => e['category'] == _selectedCategory)
              .toList();

          return _ArticleListView(
            category: _selectedCategory!,
            articles: filtered,
            onBack: () => setState(() => _selectedCategory = null),
          );
        },
      ),
    );
  }
}

// ── Category Home View ────────────────────────────────────────────────────────
class _CategoryHomeView extends StatelessWidget {
  final List<String> categories;
  final List<Map<String, dynamic>> allItems;
  final ValueChanged<String> onSelectCategory;

  const _CategoryHomeView({
    required this.categories,
    required this.allItems,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Hero header
        SliverAppBar(
          expandedHeight: 170,
          pinned: true,
          automaticallyImplyLeading: true,
          backgroundColor: kDeepBlue,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            title: const Text('Cancer Awareness',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            background: Stack(fit: StackFit.expand, children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(top: -20, right: -20,
                child: Container(width: 140, height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07)))),
              Positioned(bottom: 10, left: -30,
                child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05)))),
              Positioned(bottom: 50, right: 20,
                child: Opacity(opacity: 0.12,
                  child: const Icon(Icons.health_and_safety_rounded,
                      size: 80, color: Colors.white))),
            ]),
          ),
        ),

        // Subtitle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('Browse by Category',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1B3E))),
              const SizedBox(height: 4),
              Text('Select a topic to explore articles & guides',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ]),
          ),
        ),

        // Category grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final cat = categories[i];
                final accent = accentFor(cat);
                final count = allItems
                    .where((e) => e['category'] == cat)
                    .length;
                return _CategoryTile(
                  category: cat,
                  accent: accent,
                  icon: iconFor(cat),
                  articleCount: count,
                  onTap: () => onSelectCategory(cat),
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Category tile card ────────────────────────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final String category;
  final Color accent;
  final IconData icon;
  final int articleCount;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.accent,
    required this.icon,
    required this.articleCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: Stack(children: [
          // Background accent circle
          Positioned(
            top: -18, right: -18,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.08)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: accent, size: 20),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D1B3E),
                          height: 1.2)),
                  const SizedBox(height: 3),
                  Text('$articleCount article${articleCount == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
          // Arrow
          Positioned(
            bottom: 10, right: 10,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 12, color: accent),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Article list for a category ───────────────────────────────────────────────
class _ArticleListView extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> articles;
  final VoidCallback onBack;

  const _ArticleListView({
    required this.category,
    required this.articles,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentFor(category);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: accent,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
              title: Text(category,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              background: Stack(fit: StackFit.expand, children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent,
                        Color.lerp(accent, Colors.black, 0.15)!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(top: -10, right: -10,
                  child: Container(width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08)))),
                Positioned(bottom: 10, right: 30,
                  child: Opacity(opacity: 0.15,
                    child: Icon(iconFor(category), size: 64, color: Colors.white))),
              ]),
            ),
          ),

          if (articles.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.article_outlined, size: 56,
                      color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No articles yet',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ArticleCard(item: articles[i], accent: accent),
                  ),
                  childCount: articles.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Article card ──────────────────────────────────────────────────────────────
class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accent;
  const _ArticleCard({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item['imageUrl'] ?? '').toString().trim();

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AwarenessDetailScreen(data: item))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(width: 90, height: 100,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(accent))
                  : _placeholder(accent)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(item['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: Color(0xFF0D1B3E), height: 1.3)),
                const SizedBox(height: 5),
                Text(_previewText(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.grey.shade500, height: 1.4)),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.menu_book_rounded, size: 12, color: accent),
                  const SizedBox(width: 4),
                  Text('${_sectionCount(item)} section${_sectionCount(item) == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 11, color: accent,
                          fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(width: 28, height: 28,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_rounded, size: 14, color: accent)),
          ),
        ]),
      ),
    );
  }

  String _previewText(Map<String, dynamic> item) {
    final sections = item['sections'];
    if (sections is List && sections.isNotEmpty) {
      return (sections.first['body'] ?? '').toString();
    }
    return item['description'] ?? '';
  }

  int _sectionCount(Map<String, dynamic> item) {
    final sections = item['sections'];
    if (sections is List) return sections.length;
    final desc = item['description'] as String? ?? '';
    return desc.split('\n').where((l) =>
        RegExp(r'^\d+\.\s+').hasMatch(l.trim())).length.clamp(1, 99);
  }

  Widget _placeholder(Color accent) => Container(
      color: accent.withValues(alpha: 0.08),
      child: Center(child: Icon(Icons.article_rounded,
          color: accent.withValues(alpha: 0.4), size: 32)));
}

// ── Detail screen — section-by-section reader ─────────────────────────────────
class AwarenessDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const AwarenessDetailScreen({super.key, required this.data});

  @override
  State<AwarenessDetailScreen> createState() => _AwarenessDetailScreenState();
}

class _AwarenessDetailScreenState extends State<AwarenessDetailScreen> {
  int _currentSection = 0;

  List<Map<String, dynamic>> _getSections() {
    final raw = widget.data['sections'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((s) => Map<String, dynamic>.from(s as Map)).toList();
    }
    // Fallback: parse legacy flat description into sections
    final desc = widget.data['description'] as String? ?? '';
    return _parseLegacyDescription(desc);
  }

  List<Map<String, dynamic>> _parseLegacyDescription(String raw) {
    if (raw.trim().isEmpty) return [{'title': 'Overview', 'body': ''}];
    final lines = raw.split('\n');
    final sections = <Map<String, dynamic>>[];
    String? currentTitle;
    final buffer = StringBuffer();

    for (final line in lines) {
      final t = line.trim();
      final m = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(t);
      if (m != null) {
        if (currentTitle != null) {
          sections.add({'title': currentTitle, 'body': buffer.toString().trim()});
          buffer.clear();
        }
        currentTitle = m.group(2);
      } else if (t.isNotEmpty) {
        buffer.writeln(t);
      }
    }
    if (currentTitle != null) {
      sections.add({'title': currentTitle, 'body': buffer.toString().trim()});
    }
    if (sections.isEmpty) {
      sections.add({'title': 'Overview', 'body': raw.trim()});
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _getSections();
    final category = widget.data['category'] as String? ?? '';
    final accent = accentFor(category);
    final imageUrl = (widget.data['imageUrl'] ?? '').toString().trim();
    final section = sections[_currentSection];
    final isLast = _currentSection == sections.length - 1;
    final isFirst = _currentSection == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      body: Column(children: [
        // ── Hero + nav bar ──────────────────────────────────────────────
        SizedBox(
          height: imageUrl.isNotEmpty ? 220 : 140,
          child: Stack(fit: StackFit.expand, children: [
            imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _headerBg(accent))
                : _headerBg(accent),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.90),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            SafeArea(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(category,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                    ),
                    const SizedBox(height: 6),
                    Text(widget.data['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w800, height: 1.25)),
                  ]),
                ),
              ],
            )),
          ]),
        ),

        // ── Section tabs ────────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: List.generate(sections.length, (i) {
                  final active = i == _currentSection;
                  return GestureDetector(
                    onTap: () => setState(() => _currentSection = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? accent : accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white.withValues(alpha: 0.25)
                                : accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: active ? Colors.white : accent)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (sections[i]['title'] ?? 'Section ${i + 1}').toString(),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : accent),
                        ),
                      ]),
                    ),
                  );
                }),
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((_currentSection + 1) / sections.length),
                      minHeight: 4,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${_currentSection + 1} / ${sections.length}',
                    style: TextStyle(
                        fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),

        // ── Section content ─────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(0.05, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: SingleChildScrollView(
              key: ValueKey(_currentSection),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: accent, shape: BoxShape.circle),
                      child: Center(
                        child: Text('${_currentSection + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section['title']?.toString() ?? 'Section ${_currentSection + 1}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: accent),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                          colors: [accent, accent.withValues(alpha: 0)]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Body text
                  _buildBody(section['body']?.toString() ?? '', accent),

                  const SizedBox(height: 32),

                  // Prev / Next buttons
                  Row(children: [
                    if (!isFirst)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _currentSection--),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Previous'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: accent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (!isFirst && !isLast) const SizedBox(width: 12),
                    if (!isLast)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _currentSection++),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('Next Section'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    if (isLast)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('Done Reading'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBody(String body, Color accent) {
    if (body.trim().isEmpty) {
      return Text('No content for this section.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14));
    }
    final lines = body.split('\n');
    final widgets = <Widget>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) { widgets.add(const SizedBox(height: 8)); continue; }
      if (RegExp(r'^[-•*–]\s+').hasMatch(t)) {
        final text = t.replaceFirst(RegExp(r'^[-•*–]\s+'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(width: 7, height: 7,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text,
                style: const TextStyle(fontSize: 14.5,
                    color: Color(0xFF2C3E50), height: 1.65))),
          ]),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(t, style: const TextStyle(
              fontSize: 14.5, color: Color(0xFF2C3E50), height: 1.70)),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _headerBg(Color accent) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, Colors.black, 0.2)!],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ));
}