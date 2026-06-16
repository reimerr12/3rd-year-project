import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/lang_provider.dart';
import '../../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final _doctorsDivisionProvider = StateProvider<String?>((ref) => null);

final _doctorsListProvider =
    FutureProvider.autoDispose.family<List<DoctorModel>, String?>(
  (ref, division) async {
    return SupabaseService.instance.fetchDoctors(division: division);
  },
);

// ---------------------------------------------------------------------------
// DoctorsScreen
// ---------------------------------------------------------------------------
class DoctorsScreen extends ConsumerStatefulWidget {
  const DoctorsScreen({super.key});

  @override
  ConsumerState<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends ConsumerState<DoctorsScreen> {
  static const List<Map<String, String>> _divisions = [
    {'en': 'All', 'bn': 'সব'},
    {'en': 'Dhaka', 'bn': 'ঢাকা'},
    {'en': 'Chittagong', 'bn': 'চট্টগ্রাম'},
    {'en': 'Sylhet', 'bn': 'সিলেট'},
    {'en': 'Rajshahi', 'bn': 'রাজশাহী'},
    {'en': 'Khulna', 'bn': 'খুলনা'},
    {'en': 'Barisal', 'bn': 'বরিশাল'},
    {'en': 'Mymensingh', 'bn': 'ময়মনসিংহ'},
    {'en': 'Rangpur', 'bn': 'রংপুর'},
  ];

  static const Map<String, Map<String, String>> _specLabels = {
    'Soil Science': {'en': 'Soil Science', 'bn': 'মাটি বিজ্ঞান'},
    'Pest Control': {'en': 'Pest Control', 'bn': 'কীটনাশক'},
    'Irrigation': {'en': 'Irrigation', 'bn': 'সেচ ব্যবস্থাপনা'},
    'Crop Disease': {'en': 'Crop Disease', 'bn': 'ফসল রোগ'},
    'Horticulture': {'en': 'Horticulture', 'bn': 'উদ্যানতত্ত্ব'},
    'Agronomy': {'en': 'Agronomy', 'bn': 'শস্য বিজ্ঞান'},
    'Fisheries': {'en': 'Fisheries', 'bn': 'মৎস্যবিদ্যা'},
    'Livestock': {'en': 'Livestock', 'bn': 'পশুপালন'},
    'Plant Pathology': {'en': 'Plant Pathology', 'bn': 'উদ্ভিদ রোগতত্ত্ব'},
    'Organic Farming': {'en': 'Organic Farming', 'bn': 'জৈব কৃষি'},
  };

  static const Map<String, Map<String, String>> _dayAbbr = {
    'Saturday': {'en': 'Sat', 'bn': 'শনি'},
    'Sunday': {'en': 'Sun', 'bn': 'রবি'},
    'Monday': {'en': 'Mon', 'bn': 'সোম'},
    'Tuesday': {'en': 'Tue', 'bn': 'মঙ্গল'},
    'Wednesday': {'en': 'Wed', 'bn': 'বুধ'},
    'Thursday': {'en': 'Thu', 'bn': 'বৃহঃ'},
    'Friday': {'en': 'Fri', 'bn': 'শুক্র'},
  };

  String _dayLabel(String day, bool isBn) {
    final entry = _dayAbbr[day];
    if (entry == null) return day;
    return isBn ? entry['bn']! : entry['en']!;
  }

  String _specLabel(String? spec, bool isBn) {
    if (spec == null) return '';
    final entry = _specLabels[spec];
    if (entry == null) return spec;
    return isBn ? entry['bn']! : entry['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(langProvider);
    final selectedDivision = ref.watch(_doctorsDivisionProvider);
    final doctorsAsync = ref.watch(_doctorsListProvider(selectedDivision));

    return Scaffold(
      backgroundColor: AppTheme.surfaceGreen,
      appBar: _buildAppBar(bn),
      body: Column(
        children: [
          _buildDivisionFilter(bn, selectedDivision),
          Expanded(
            child: doctorsAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryGreen)),
              error: (e, _) => _buildError(bn, e),
              data: (doctors) => doctors.isEmpty
                  ? _buildEmpty(bn)
                  : RefreshIndicator(
                      color: AppTheme.primaryGreen,
                      onRefresh: () async {
                        ref.invalidate(_doctorsListProvider(selectedDivision));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: doctors.length,
                        itemBuilder: (context, index) => _DoctorCard(
                          doctor: doctors[index],
                          isBn: bn,
                          dayLabel: _dayLabel,
                          specLabel: _specLabel,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool bn) {
    return AppBar(
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: BackButton(
        onPressed: () =>
            Navigator.of(context).pushReplacementNamed(AppRouter.home),
      ),
      title: Text(
        bn ? 'কৃষি বিশেষজ্ঞ' : 'Agricultural Experts',
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  Widget _buildDivisionFilter(bool bn, String? selected) {
    return Container(
      color: AppTheme.primaryGreen,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceGreen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 0, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                bn ? 'বিভাগ অনুযায়ী' : 'Filter by Division',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary.withValues(alpha: 0.5),
                    letterSpacing: 0.5),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _divisions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final div = _divisions[i];
                  final value = i == 0 ? null : div['en']!;
                  final isSelected = selected == value;
                  return GestureDetector(
                    onTap: () => ref
                        .read(_doctorsDivisionProvider.notifier)
                        .state = value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppTheme.primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.borderGrey),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2))
                              ]
                            : [],
                      ),
                      child: Text(
                        bn ? div['bn']! : div['en']!,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildError(bool bn, Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red.shade300, size: 48),
            const SizedBox(height: 12),
            Text(bn ? 'তথ্য লোড হয়নি' : 'Failed to load',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(e.toString(),
                style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary.withValues(alpha: 0.5)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => ref.invalidate(_doctorsListProvider),
              child: Text(bn ? 'আবার চেষ্টা করুন' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool bn) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search_rounded,
              size: 64, color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text(
            bn ? 'এই বিভাগে কোনো বিশেষজ্ঞ নেই' : 'No experts in this division',
            style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DoctorCard
// ---------------------------------------------------------------------------
class _DoctorCard extends StatefulWidget {
  final DoctorModel doctor;
  final bool isBn;
  final String Function(String, bool) dayLabel;
  final String Function(String?, bool) specLabel;

  const _DoctorCard({
    required this.doctor,
    required this.isBn,
    required this.dayLabel,
    required this.specLabel,
  });

  @override
  State<_DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<_DoctorCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  Color _specColor(String? spec) {
    const colors = [
      Color(0xFF2D6A4F),
      Color(0xFF1B4332),
      Color(0xFF40916C),
      Color(0xFF52B788),
      Color(0xFF1A535C),
      Color(0xFF4E598C),
      Color(0xFF6B4226),
      Color(0xFF7B2D00),
    ];
    if (spec == null) return AppTheme.primaryGreen;
    return colors[spec.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;
    final isBn = widget.isBn;
    final specColor = _specColor(d.specialization);

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _expanded
                  ? specColor.withValues(alpha: 0.35)
                  : AppTheme.borderGrey),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: _expanded ? 0.07 : 0.04),
                blurRadius: _expanded ? 14 : 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: specColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: specColor.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Center(
                        child: Text(_initials(d.name),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: specColor,
                                letterSpacing: 0.5))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          if (d.specialization != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: specColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                  widget.specLabel(d.specialization, isBn),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: specColor)),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.location_on_rounded,
                                size: 13,
                                color: AppTheme.textPrimary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(width: 3),
                            Text(_locationText(d, isBn),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textPrimary
                                        .withValues(alpha: 0.55))),
                          ]),
                        ]),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textPrimary.withValues(alpha: 0.35),
                        size: 22),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Column(children: [
                const Divider(
                    height: 1,
                    color: AppTheme.borderGrey,
                    indent: 16,
                    endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(children: [
                    _InfoRow(
                        icon: Icons.phone_rounded,
                        iconColor: AppTheme.primaryGreen,
                        label: isBn ? 'ফোন' : 'Phone',
                        value: d.phone),
                    if (d.email != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                          icon: Icons.email_rounded,
                          iconColor: const Color(0xFF4E598C),
                          label: isBn ? 'ইমেইল' : 'Email',
                          value: d.email!),
                    ],
                    if (d.availableHours != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                          icon: Icons.access_time_rounded,
                          iconColor: const Color(0xFF6B4226),
                          label: isBn ? 'সময়' : 'Hours',
                          value: d.availableHours!),
                    ],
                    if (d.availableDays.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 15,
                                color: AppTheme.textPrimary
                                    .withValues(alpha: 0.45)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: d.availableDays
                                  .map((day) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppTheme.primaryGreen
                                                  .withValues(alpha: 0.2)),
                                        ),
                                        child: Text(widget.dayLabel(day, isBn),
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primaryGreen
                                                    .withValues(alpha: 0.85))),
                                      ))
                                  .toList(),
                            )),
                          ]),
                    ],
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String _locationText(DoctorModel d, bool isBn) {
    final parts = <String>[];
    if (d.district != null) parts.add(d.district!);
    if (d.division != null) parts.add(d.division!);
    if (parts.isEmpty) return isBn ? 'অজানা' : 'Unknown';
    return parts.join(', ');
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Icon(icon, size: 15, color: iconColor),
      const SizedBox(width: 8),
      Text('$label: ',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary.withValues(alpha: 0.55))),
      Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis)),
    ]);
  }
}
