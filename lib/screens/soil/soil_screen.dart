import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../core/theme.dart';
import '../../providers/lang_provider.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
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

  factory SoilEntry.fromMap(Map<String, dynamic> m) {
    return SoilEntry(
      id: m['id'] as String,
      division: m['division'] as String,
      soilType: m['soil_type'] as String,
      recommendedCrops:
          List<String>.from(m['recommended_crops'] as List? ?? []),
      tipsEn: m['tips_en'] as String? ?? '',
      tipsBn: m['tips_bn'] as String? ?? '',
      phRange: m['ph_range'] as String? ?? '—',
      waterRetention: m['water_retention'] as String? ?? '—',
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final soilProvider =
    AsyncNotifierProvider<SoilNotifier, List<SoilEntry>>(SoilNotifier.new);

class SoilNotifier extends AsyncNotifier<List<SoilEntry>> {
  @override
  Future<List<SoilEntry>> build() => _fetch();

  Future<List<SoilEntry>> _fetch() async {
    final data = await Supabase.instance.client
        .from('soil_lookup')
        .select()
        .order('division', ascending: true);
    return (data as List)
        .map((e) => SoilEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

// ---------------------------------------------------------------------------
// Division data
// ---------------------------------------------------------------------------
class _Division {
  final String key;
  final String en;
  final String bn;
  const _Division(this.key, this.en, this.bn);
}

const _kAllKey = '__all__';
const _kDivisions = [
  _Division(_kAllKey, 'All Divisions', 'সব বিভাগ'),
  _Division('ঢাকা', 'Dhaka', 'ঢাকা'),
  _Division('চট্টগ্রাম', 'Chittagong', 'চট্টগ্রাম'),
  _Division('রাজশাহী', 'Rajshahi', 'রাজশাহী'),
  _Division('খুলনা', 'Khulna', 'খুলনা'),
  _Division('বরিশাল', 'Barisal', 'বরিশাল'),
  _Division('সিলেট', 'Sylhet', 'সিলেট'),
  _Division('রংপুর', 'Rangpur', 'রংপুর'),
  _Division('ময়মনসিংহ', 'Mymensingh', 'ময়মনসিংহ'),
];

IconData _soilIcon(String soilType) {
  if (soilType.contains('এঁটেল')) return Icons.layers;
  if (soilType.contains('দোআঁশ')) return Icons.grass;
  if (soilType.contains('লাল')) return Icons.terrain;
  if (soilType.contains('বরেন্দ্র')) return Icons.landscape;
  if (soilType.contains('চা')) return Icons.local_cafe;
  if (soilType.contains('পলি')) return Icons.water_drop;
  if (soilType.contains('লবণ')) return Icons.waves;
  if (soilType.contains('তিস্তা')) return Icons.water;
  if (soilType.contains('পাহাড়')) return Icons.filter_hdr;
  if (soilType.contains('চর')) return Icons.beach_access;
  return Icons.yard;
}

Color _soilColor(String soilType) {
  if (soilType.contains('এঁটেল')) return const Color(0xFF795548);
  if (soilType.contains('দোআঁশ')) return const Color(0xFF558B2F);
  if (soilType.contains('লাল')) return const Color(0xFFBF360C);
  if (soilType.contains('বরেন্দ্র')) return const Color(0xFF6D4C41);
  if (soilType.contains('চা')) return const Color(0xFF33691E);
  if (soilType.contains('পলি')) return const Color(0xFF0277BD);
  if (soilType.contains('লবণ')) return const Color(0xFF00838F);
  if (soilType.contains('তিস্তা')) return const Color(0xFF1565C0);
  if (soilType.contains('পাহাড়')) return const Color(0xFF4E342E);
  if (soilType.contains('চর')) return const Color(0xFFF57F17);
  return AppTheme.primaryGreen;
}

String _soilTypeEn(String soilType) {
  if (soilType.contains('এঁটেল')) return 'Clay Soil';
  if (soilType.contains('দোআঁশ')) return 'Loam Soil';
  if (soilType.contains('লাল')) return 'Red Laterite Soil';
  if (soilType.contains('বরেন্দ্র')) return 'Barind Soil';
  if (soilType.contains('চা')) return 'Tea Garden Soil';
  if (soilType.contains('লবণ')) return 'Saline Coastal Soil';
  if (soilType.contains('তিস্তা')) return 'Tista Alluvial Soil';
  if (soilType.contains('পাহাড়')) return 'Hill Soil';
  if (soilType.contains('চর')) return 'Char Land Soil';
  if (soilType.contains('পলি')) return 'Alluvial Soil';
  return soilType;
}

Color _retentionColor(String r) {
  switch (r.toLowerCase()) {
    case 'high':
      return const Color(0xFF1565C0);
    case 'medium':
      return const Color(0xFF2E7D32);
    case 'low':
      return const Color(0xFFE65100);
    default:
      return AppTheme.textSecondary;
  }
}

String _retentionLabel(String r, {required bool bn}) {
  switch (r.toLowerCase()) {
    case 'high':
      return bn ? 'উচ্চ' : 'High';
    case 'medium':
      return bn ? 'মাঝারি' : 'Medium';
    case 'low':
      return bn ? 'কম' : 'Low';
    default:
      return r;
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class SoilScreen extends ConsumerStatefulWidget {
  const SoilScreen({super.key});

  @override
  ConsumerState<SoilScreen> createState() => _SoilScreenState();
}

class _SoilScreenState extends ConsumerState<SoilScreen> {
  String _selectedKey = _kAllKey;

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(langProvider);
    final soilAsync = ref.watch(soilProvider);

    String t(String bangla, String english) => bn ? bangla : english;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('মাটির গুণমান', 'Soil Quality'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Column(
        children: [
          _DivisionFilter(
            selectedKey: _selectedKey,
            bn: bn,
            onChanged: (key) => setState(() => _selectedKey = key),
          ),
          Expanded(
            child: soilAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryGreen)),
              error: (e, _) => _ErrorView(
                bn: bn,
                onRetry: () => ref.read(soilProvider.notifier).refresh(),
              ),
              data: (entries) {
                final filtered = _selectedKey == _kAllKey
                    ? entries
                    : entries.where((e) => e.division == _selectedKey).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 56,
                            color: AppTheme.borderGrey.withValues(alpha: 0.8)),
                        const SizedBox(height: 12),
                        Text(
                          t('এই বিভাগে কোনো তথ্য পাওয়া যায়নি',
                              'No data found for this division'),
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  onRefresh: () => ref.read(soilProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) =>
                        _SoilCard(entry: filtered[i], bn: bn),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DivisionFilter extends StatelessWidget {
  final String selectedKey;
  final bool bn;
  final ValueChanged<String> onChanged;
  const _DivisionFilter(
      {required this.selectedKey, required this.bn, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: _kDivisions.length,
          itemBuilder: (_, i) {
            final div = _kDivisions[i];
            final isSelected = selectedKey == div.key;
            return GestureDetector(
              onTap: () => onChanged(div.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.borderGrey),
                ),
                child: Text(bn ? div.bn : div.en,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SoilCard extends StatefulWidget {
  final SoilEntry entry;
  final bool bn;
  const _SoilCard({required this.entry, required this.bn});

  @override
  State<_SoilCard> createState() => _SoilCardState();
}

class _SoilCardState extends State<_SoilCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  SoilEntry get e => widget.entry;
  bool get bn => widget.bn;
  Color get _accent => _soilColor(e.soilType);

  String get _divisionDisplay {
    if (!bn) {
      return _kDivisions
          .firstWhere((d) => d.key == e.division,
              orElse: () => _Division(e.division, e.division, e.division))
          .en;
    }
    return e.division;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderGrey.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14)),
                    child:
                        Icon(_soilIcon(e.soilType), color: _accent, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _accent.withValues(alpha: 0.3)),
                            ),
                            child: Text(_divisionDisplay,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _accent)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(bn ? e.soilType : _soilTypeEn(e.soilType),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                height: 1.2)),
                        if (!bn) ...[
                          const SizedBox(height: 2),
                          Text(e.soilType,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                        const SizedBox(height: 8),
                        Row(children: [
                          _StatBadge(
                              icon: Icons.science_outlined,
                              label: 'pH ${e.phRange}',
                              color: const Color(0xFF6A1B9A)),
                          const SizedBox(width: 8),
                          _StatBadge(
                              icon: Icons.water_drop_outlined,
                              label: _retentionLabel(e.waterRetention, bn: bn),
                              color: _retentionColor(e.waterRetention)),
                        ]),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnim),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: _accent, size: 22),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: AppTheme.borderGrey.withValues(alpha: 0.6)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                          icon: Icons.eco,
                          label: bn ? 'প্রস্তাবিত ফসল' : 'Recommended Crops',
                          color: AppTheme.primaryGreen),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: e.recommendedCrops
                            .map((crop) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppTheme.primaryGreen
                                            .withValues(alpha: 0.25)),
                                  ),
                                  child: Text(crop,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.darkGreen,
                                          fontWeight: FontWeight.w600)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      _SoilIndicatorsRow(entry: e, bn: bn),
                      const SizedBox(height: 20),
                      _SectionLabel(
                          icon: Icons.article_outlined,
                          label: bn ? 'বিস্তারিত বিবরণ' : 'Detailed Analysis',
                          color: _accent),
                      const SizedBox(height: 12),
                      ..._buildBlogParagraphs(
                          bn ? e.tipsBn : e.tipsEn, bn, _accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBlogParagraphs(String text, bool isBn, Color accent) {
    final paragraphs = text
        .split(RegExp(r'\n\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final widgets = <Widget>[];
    for (int i = 0; i < paragraphs.length; i++) {
      if (i == 0) {
        widgets.add(Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 3,
                height: 60,
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(
                child: Text(paragraphs[i],
                    style: TextStyle(
                        fontSize: isBn ? 13.5 : 13,
                        height: 1.7,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500))),
          ]),
        ));
      } else {
        widgets.add(Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(paragraphs[i],
                style: const TextStyle(
                    fontSize: 13, height: 1.75, color: Color(0xFF424242)))));
      }
    }
    return widgets;
  }
}

class _SoilIndicatorsRow extends StatelessWidget {
  final SoilEntry entry;
  final bool bn;
  const _SoilIndicatorsRow({required this.entry, required this.bn});

  @override
  Widget build(BuildContext context) {
    final retentionColor = _retentionColor(entry.waterRetention);
    final retentionFraction = entry.waterRetention.toLowerCase() == 'high'
        ? 1.0
        : entry.waterRetention.toLowerCase() == 'medium'
            ? 0.6
            : 0.3;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAF6),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.borderGrey.withValues(alpha: 0.5))),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.science_outlined,
              size: 16, color: Color(0xFF6A1B9A)),
          const SizedBox(width: 8),
          Text(bn ? 'pH পরিসীমা' : 'pH Range',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(entry.phRange,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6A1B9A))),
        ]),
        const SizedBox(height: 10),
        _PhBar(phRange: entry.phRange),
        const SizedBox(height: 14),
        Row(children: [
          Icon(Icons.water_drop_outlined, size: 16, color: retentionColor),
          const SizedBox(width: 8),
          Text(bn ? 'পানি ধারণ ক্ষমতা' : 'Water Retention',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(_retentionLabel(entry.waterRetention, bn: bn),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: retentionColor)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: retentionFraction,
              minHeight: 6,
              backgroundColor: AppTheme.borderGrey.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(retentionColor)),
        ),
      ]),
    );
  }
}

class _PhBar extends StatelessWidget {
  final String phRange;
  const _PhBar({required this.phRange});

  @override
  Widget build(BuildContext context) {
    double low = 7.0, high = 7.0;
    try {
      final parts = phRange.split(RegExp(r'[–\-—]'));
      if (parts.length == 2) {
        low = double.parse(parts[0].trim());
        high = double.parse(parts[1].trim());
      }
    } catch (_) {}
    final lowFrac = low / 14.0;
    final highFrac = high / 14.0;
    return Column(children: [
      Stack(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
                height: 8,
                child: Row(children: [
                  _seg(0.5 / 14, const Color(0xFFB71C1C)),
                  _seg(1.0 / 14, const Color(0xFFE53935)),
                  _seg(1.5 / 14, const Color(0xFFEF6C00)),
                  _seg(1.0 / 14, const Color(0xFFFDD835)),
                  _seg(1.0 / 14, const Color(0xFF9CCC65)),
                  _seg(1.0 / 14, const Color(0xFF4CAF50)),
                  _seg(1.0 / 14, const Color(0xFF26A69A)),
                  _seg(2.0 / 14, const Color(0xFF1E88E5)),
                  _seg(2.0 / 14, const Color(0xFF1565C0)),
                  _seg(2.0 / 14, const Color(0xFF6A1B9A)),
                ]))),
        Positioned.fill(child: LayoutBuilder(builder: (_, c) {
          final w = c.maxWidth;
          return Stack(children: [
            Positioned(
                left: 0,
                width: w * lowFrac,
                top: 0,
                bottom: 0,
                child: Container(color: Colors.white.withValues(alpha: 0.6))),
            Positioned(
                left: w * highFrac,
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(color: Colors.white.withValues(alpha: 0.6))),
          ]);
        })),
      ]),
      const SizedBox(height: 4),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('0', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
        Text('7', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
        Text('14',
            style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ]),
    ]);
  }

  Widget _seg(double flex, Color color) =>
      Expanded(flex: (flex * 1000).toInt(), child: Container(color: color));
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final bool bn;
  final VoidCallback onRetry;
  const _ErrorView({required this.bn, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
        const SizedBox(height: 12),
        Text(bn ? 'তথ্য লোড করতে ব্যর্থ হয়েছে' : 'Failed to load data',
            style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white),
          child: Text(bn ? 'আবার চেষ্টা করুন' : 'Try Again'),
        ),
      ]),
    );
  }
}
