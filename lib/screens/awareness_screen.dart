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
  final _searchCtrl = TextEditingController();
  String _query = '';

  final _stream = FirebaseFirestore.instance
      .collection('awareness_content')
      .orderBy('createdAt', descending: false)
      .snapshots();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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

          // Filter by search query
          final q = _query.toLowerCase().trim();
          final filtered = q.isEmpty
              ? allItems
              : allItems.where((e) {
                  final title = (e['title'] ?? '').toString().toLowerCase();
                  final cat   = (e['category'] ?? '').toString().toLowerCase();
                  return title.contains(q) || cat.contains(q);
                }).toList();

          // Group by category, preserve order
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final item in filtered) {
            final cat = (item['category'] as String?) ?? 'General';
            grouped.putIfAbsent(cat, () => []).add(item);
          }
          final categories = grouped.keys.toList()..sort();

          return CustomScrollView(
            slivers: [
              // ── Hero header ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 150,
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
                    Positioned(
                        top: -20, right: -20,
                        child: Container(width: 140, height: 140,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07)))),
                    Positioned(
                        bottom: 10, left: -30,
                        child: Container(width: 100, height: 100,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05)))),
                    Positioned(
                        bottom: 40, right: 20,
                        child: Opacity(opacity: 0.12,
                          child: const Icon(Icons.health_and_safety_rounded,
                              size: 72, color: Colors.white))),
                  ]),
                ),
              ),

              // ── Search bar ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search articles & topics…',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: kDeepBlue, size: 22),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18, color: Colors.grey),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Empty state ──────────────────────────────────────────
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off_rounded,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No articles found for "$_query"',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14)),
                    ]),
                  ),
                )
              else
                // ── Category sections with article cards ─────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, sectionIndex) {
                        final cat = categories[sectionIndex];
                        final accent = accentFor(cat);
                        final articles = grouped[cat]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Category header chip ──────────────────
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16, bottom: 10),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(9)),
                                  child: Icon(iconFor(cat),
                                      color: accent, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text(cat,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: accent)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.10),
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  child: Text(
                                      '${articles.length} article'
                                      '${articles.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: accent,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            ),

                            // ── Article cards for this category ───────
                            ...articles.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ArticleCard(
                                  item: item, accent: accent),
                            )),
                          ],
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),
            ],
          );
        },
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
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => AwarenessDetailScreen(data: item))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          // Image / placeholder
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 88,
              height: 96,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(accent))
                  : _placeholder(accent),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0D1B3E),
                          height: 1.3)),
                  const SizedBox(height: 4),
                  Text(_previewText(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                          height: 1.4)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.menu_book_rounded, size: 12, color: accent),
                    const SizedBox(width: 4),
                    Text(
                        '${_sectionCount(item)} section'
                        '${_sectionCount(item) == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 14, color: accent),
            ),
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
    return desc
        .split('\n')
        .where((l) => RegExp(r'^\d+\.\s+').hasMatch(l.trim()))
        .length
        .clamp(1, 99);
  }

  Widget _placeholder(Color accent) => Container(
      color: accent.withValues(alpha: 0.08),
      child: Center(
          child: Icon(Icons.article_rounded,
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
          sections
              .add({'title': currentTitle, 'body': buffer.toString().trim()});
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
    final section = sections[_currentSection];
    final isLast = _currentSection == sections.length - 1;
    final isFirst = _currentSection == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.5)),
            Text(widget.data['title'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
      body: Column(children: [

        // ── Section tabs ──────────────────────────────────────────────
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
                        color: active
                            ? accent
                            : accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 16,
                          height: 16,
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
                                    color:
                                        active ? Colors.white : accent)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (sections[i]['title'] ?? 'Section ${i + 1}')
                              .toString(),
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
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),

        // ── Section content ───────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0.05, 0), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: SingleChildScrollView(
              key: ValueKey(_currentSection),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration:
                          BoxDecoration(color: accent, shape: BoxShape.circle),
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
                        section['title']?.toString() ??
                            'Section ${_currentSection + 1}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
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
                  _buildBody(
                      section['body']?.toString() ?? '', accent),
                  const SizedBox(height: 32),
                  Row(children: [
                    if (!isFirst)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _currentSection--),
                          icon: const Icon(Icons.arrow_back_rounded,
                              size: 16),
                          label: const Text('Previous'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: accent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (!isFirst && !isLast) const SizedBox(width: 12),
                    if (!isLast)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _currentSection++),
                          icon: const Icon(Icons.arrow_forward_rounded,
                              size: 16),
                          label: const Text('Next Section'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    if (isLast)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_circle_rounded,
                              size: 16),
                          label: const Text('Done Reading'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
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
      if (t.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      if (RegExp(r'^[-•*–]\s+').hasMatch(t)) {
        final text = t.replaceFirst(RegExp(r'^[-•*–]\s+'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFF2C3E50),
                        height: 1.65))),
          ]),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF2C3E50),
                  height: 1.70)),
        ));
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _headerBg(Color accent) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, Colors.black, 0.2)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ));
}