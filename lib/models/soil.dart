import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../core/router.dart';

// ── Model ──────────────────────────────────────────────────────
class SoilEntry {
  final String id;
  final String division;
  final String soilType;
  final List<String> recommendedCrops;
  final String tipsEn;
  final String tipsBn;
  final String phRange;
  final String waterRetention;

  const SoilEntry({
    required this.id,
    required this.division,
    required this.soilType,
    required this.recommendedCrops,
    required this.tipsEn,
    required this.tipsBn,
    required this.phRange,
    required this.waterRetention,
  });

  factory SoilEntry.fromMap(Map<String, dynamic> map) {
    return SoilEntry(
      id: map['id'] as String,
      division: map['division'] as String,
      soilType: map['soil_type'] as String,
      recommendedCrops:
          List<String>.from(map['recommended_crops'] as List? ?? []),
      tipsEn: map['tips_en'] as String? ?? '',
      tipsBn: map['tips_bn'] as String? ?? '',
      phRange: map['ph_range'] as String? ?? '—',
      waterRetention: map['water_retention'] as String? ?? '—',
    );
  }

  String get waterRetentionBn {
    switch (waterRetention) {
      case 'high':
        return 'বেশি';
      case 'medium':
        return 'মাঝারি';
      case 'low':
        return 'কম';
      default:
        return waterRetention;
    }
  }

  Color get waterRetentionColor {
    switch (waterRetention) {
      case 'high':
        return const Color(0xFF2196F3);
      case 'medium':
        return const Color(0xFF4CAF50);
      case 'low':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────
final _soilProvider = FutureProvider.family<List<SoilEntry>, String>(
  (ref, division) async {
    final data = await Supabase.instance.client
        .from('soil_lookup')
        .select()
        .eq('division', division)
        .order('soil_type', ascending: true);
    return (data as List)
        .map((e) => SoilEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  },
);

// ── Screen ────────────────────────────────────────────────────
class SoilScreen extends ConsumerStatefulWidget {
  const SoilScreen({super.key});

  @override
  ConsumerState<SoilScreen> createState() => _SoilScreenState();
}

class _SoilScreenState extends ConsumerState<SoilScreen> {
  static const _divisions = [
    'ঢাকা',
    'চট্টগ্রাম',
    'রাজশাহী',
    'খুলনা',
    'বরিশাল',
    'সিলেট',
    'রংপুর',
    'ময়মনসিংহ',
  ];

  String _selectedDivision = 'ঢাকা';
  bool _isBn = true;

  // Soil type → icon mapping
  IconData _soilIcon(String soilType) {
    if (soilType.contains('এঁটেল')) return Icons.water_drop_outlined;
    if (soilType.contains('দোআঁশ')) return Icons.grass_outlined;
    if (soilType.contains('বালু')) return Icons.terrain_outlined;
    if (soilType.contains('লাল')) return Icons.circle_outlined;
    if (soilType.contains('পাহাড়')) return Icons.landscape_outlined;
    if (soilType.contains('বরেন্দ্র')) return Icons.wb_sunny_outlined;
    if (soilType.contains('লবণ')) return Icons.waves_outlined;
    if (soilType.contains('পলি')) return Icons.opacity_outlined;
    if (soilType.contains('চর')) return Icons.beach_access_outlined;
    if (soilType.contains('চা')) return Icons.eco_outlined;
    return Icons.foundation_outlined;
  }

  // Soil type → accent color
  Color _soilColor(String soilType) {
    if (soilType.contains('এঁটেল')) return const Color(0xFF5C6BC0);
    if (soilType.contains('দোআঁশ')) return AppTheme.primaryGreen;
    if (soilType.contains('বালু')) return const Color(0xFFEF8C00);
    if (soilType.contains('লাল')) return const Color(0xFFE53935);
    if (soilType.contains('পাহাড়')) return const Color(0xFF6D4C41);
    if (soilType.contains('বরেন্দ্র')) return const Color(0xFF8D6E63);
    if (soilType.contains('লবণ')) return const Color(0xFF0288D1);
    if (soilType.contains('পলি')) return const Color(0xFF00897B);
    if (soilType.contains('চর')) return const Color(0xFFF9A825);
    if (soilType.contains('চা')) return const Color(0xFF558B2F);
    return AppTheme.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    final soilAsync = ref.watch(_soilProvider(_selectedDivision));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // EN / BN toggle
              GestureDetector(
                onTap: () => setState(() => _isBn = !_isBn),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isBn ? 'EN' : 'বাং',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.landscape,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isBn ? 'মাটির গুণমান' : 'Soil Quality',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _isBn
                                      ? 'বিভাগ অনুযায়ী মাটির তথ্য'
                                      : 'Soil info by division',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Division Selector ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _divisions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final div = _divisions[i];
                    final isSelected = div == _selectedDivision;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDivision = div),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          div,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Division header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$_selectedDivision ${_isBn ? 'বিভাগ' : 'Division'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          soilAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      _isBn ? 'তথ্য লোড করা যায়নি' : 'Failed to load data',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(_soilProvider(_selectedDivision)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: Text(_isBn ? 'আবার চেষ্টা করুন' : 'Try again'),
                    ),
                  ],
                ),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _isBn
                              ? 'এই বিভাগের মাটির তথ্য পাওয়া যায়নি'
                              : 'No soil data for this division',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == entries.length) {
                      return const SizedBox(height: 40);
                    }
                    return _SoilBlogCard(
                      entry: entries[index],
                      isBn: _isBn,
                      soilIcon: _soilIcon(entries[index].soilType),
                      accentColor: _soilColor(entries[index].soilType),
                    );
                  },
                  childCount: entries.length + 1,
                ),
              );
            },
          ),
        ],
      ),
      // Bottom nav consistent with rest of app
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, AppRouter.home);
                break;
              case 1:
                Navigator.pushReplacementNamed(context, AppRouter.market);
                break;
              case 2:
                Navigator.pushReplacementNamed(context, AppRouter.services);
                break;
              case 3:
                Navigator.pushReplacementNamed(context, AppRouter.profile);
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: 'হোম'),
            BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined), label: 'বাজার'),
            BottomNavigationBarItem(
                icon: Icon(Icons.miscellaneous_services_outlined),
                label: 'সেবা'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'প্রোফাইল'),
          ],
        ),
      ),
    );
  }
}

// ── Blog Card ─────────────────────────────────────────────────
class _SoilBlogCard extends StatefulWidget {
  final SoilEntry entry;
  final bool isBn;
  final IconData soilIcon;
  final Color accentColor;

  const _SoilBlogCard({
    required this.entry,
    required this.isBn,
    required this.soilIcon,
    required this.accentColor,
  });

  @override
  State<_SoilBlogCard> createState() => _SoilBlogCardState();
}

class _SoilBlogCardState extends State<_SoilBlogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final color = widget.accentColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Soil icon circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(widget.soilIcon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.soilType,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e.division} ${widget.isBn ? 'বিভাগ' : 'Division'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Stats row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.science_outlined,
                  label: widget.isBn ? 'pH মাত্রা' : 'pH Range',
                  value: e.phRange,
                  color: color,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.water_outlined,
                  label: widget.isBn ? 'পানি ধারণ' : 'Water Retention',
                  value: widget.isBn ? e.waterRetentionBn : e.waterRetention,
                  color: e.waterRetentionColor,
                ),
              ],
            ),
          ),

          // ── Recommended crops ─────────────────────────────────
          if (e.recommendedCrops.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco_outlined,
                          color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.isBn ? 'উপযুক্ত ফসল' : 'Recommended Crops',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: e.recommendedCrops.map((crop) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          crop,
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // ── Tips (blog body) ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_outlined,
                        color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      widget.isBn ? 'চাষের পরামর্শ' : 'Farming Tips',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Show preview or full text based on expanded state
                AnimatedCrossFade(
                  firstChild: Text(
                    widget.isBn ? e.tipsBn : e.tipsEn,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                  secondChild: Text(
                    widget.isBn ? e.tipsBn : e.tipsEn,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),

          // ── Read more / less ──────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Row(
                children: [
                  Text(
                    _expanded
                        ? (widget.isBn ? 'কম দেখুন' : 'Show less')
                        : (widget.isBn ? 'আরও পড়ুন' : 'Read more'),
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: color,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
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
