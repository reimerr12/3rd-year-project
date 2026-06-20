import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/guidelines.dart';
import '../../providers/guidelines_provider.dart';
import '../../providers/lang_provider.dart';

// guidelinesLangProvider now derives from langProvider — always mirrors the global toggle.
// It's a Provider<bool> (read-only), not a StateProvider.
final guidelinesLangProvider = Provider<bool>((ref) => ref.watch(langProvider));

class GuidelinesScreen extends ConsumerStatefulWidget {
  const GuidelinesScreen({super.key});

  @override
  ConsumerState<GuidelinesScreen> createState() => _GuidelinesScreenState();
}

class _GuidelinesScreenState extends ConsumerState<GuidelinesScreen> {
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'en': 'All Crops', 'bn': 'সব ফসল'},
    {'id': 'grain', 'en': 'Grains', 'bn': 'দানাদার'},
    {'id': 'vegetable', 'en': 'Vegetables', 'bn': 'সবজি'},
    {'id': 'fruit', 'en': 'Fruits', 'bn': 'ফল'},
    {'id': 'spice', 'en': 'Spices', 'bn': 'মসলা'},
    {'id': 'oilseed', 'en': 'Oilseeds', 'bn': 'তৈলবীজ'},
    {'id': 'pulse', 'en': 'Pulses', 'bn': 'ডাল'},
  ];

  @override
  Widget build(BuildContext context) {
    // isBangla is now derived from the global langProvider via guidelinesLangProvider
    final isBangla = ref.watch(guidelinesLangProvider);
    final asyncGuidelines = ref.watch(fetchGuidelinesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        title: Text(
          isBangla ? 'চাষ নির্দেশিকা লাইব্রেরি' : 'Farming Guidelines Library',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        // No language toggle — controlled globally from home screen
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(isBangla ? cat['bn']! : cat['en']!),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.surfaceGreen,
                    checkmarkColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() => _selectedCategory = cat['id']!);
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: asyncGuidelines.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryGreen)),
              error: (err, stack) => Center(
                child: Text(isBangla
                    ? 'উপাত্ত লোড করা যায়নি।'
                    : 'Failed to fetch guideline data.'),
              ),
              data: (data) {
                final filteredList = _selectedCategory == 'all'
                    ? data
                    : data
                        .where((e) => e.category == _selectedCategory)
                        .toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      isBangla
                          ? 'কোন ফসল খুঁজে পাওয়া যায়নি।'
                          : 'No crops found in this cluster.',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final crop = filteredList[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CropDetailTabsScreen(crop: crop))),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  color: Color(0xFFF0F4F0),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: CachedNetworkImage(
                                    imageUrl: crop.coverImage ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorWidget: (c, e, o) => const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: AppTheme.textHint,
                                        size: 40),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBangla ? crop.nameBn : crop.nameEn,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isBangla
                                        ? (crop.descriptionBn ?? '')
                                        : (crop.descriptionEn ?? ''),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CropDetailTabsScreen extends ConsumerWidget {
  final CropGuideline crop;
  const CropDetailTabsScreen({super.key, required this.crop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBangla = ref.watch(guidelinesLangProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryGreen,
          title: Text(isBangla ? crop.nameBn : crop.nameEn,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: isBangla ? 'চাষ পদ্ধতি' : 'Lifecycle Steps'),
              Tab(text: isBangla ? 'রোগ ও প্রতিকার' : 'Infections & Remedies'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLifecycleTab(context, isBangla),
            _buildInfectionsTab(context, isBangla),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleTab(BuildContext context, bool isBangla) {
    if (crop.steps.isEmpty) {
      return Center(
          child: Text(
              isBangla ? 'কোন ধাপ রেকর্ড নেই।' : 'No data records found.'));
    }

    final sortedSteps = List<LifecycleStep>.from(crop.steps)
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSteps.length,
      itemBuilder: (context, index) {
        final step = sortedSteps[index];
        // ignore: dead_null_aware_expression
        final instructionsText = isBangla
            // ignore: dead_null_aware_expression
            ? (step.instructionsBn ?? '').trim()
            // ignore: dead_null_aware_expression
            : (step.instructionsEn ?? '').trim();
        final rawBlogText = isBangla ? step.blogContentBn : step.blogContentEn;
        final displayBlogText =
            (rawBlogText != null && rawBlogText.trim().isNotEmpty)
                ? rawBlogText.trim()
                : instructionsText;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.surfaceGreen,
                    radius: 14,
                    child: Text('${step.stepOrder}',
                        style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(isBangla ? step.titleBn : step.titleEn,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary))),
                ]),
                const Divider(height: 24, thickness: 0.8),
                Text(
                  instructionsText.isNotEmpty
                      ? instructionsText
                      : (isBangla
                          ? 'কোনো চাষ নির্দেশাবলী নেই।'
                          : 'No cultivation guidelines recorded.'),
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                if (step.videoYoutubeId != null &&
                    step.videoYoutubeId!.trim().isNotEmpty) ...[
                  YouTubeEmbeddedPlayer(videoId: step.videoYoutubeId!.trim()),
                  const SizedBox(height: 16),
                ],
                if (displayBlogText.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.borderGrey.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.menu_book_outlined,
                                size: 18, color: AppTheme.primaryGreen),
                            const SizedBox(width: 6),
                            Text(
                                isBangla
                                    ? 'বিস্তারিত চাষ পদ্ধতি ব্লগ'
                                    : 'Detailed Cultivation Blog',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen)),
                          ]),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(height: 1)),
                          Text(displayBlogText,
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppTheme.textPrimary)),
                        ]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfectionsTab(BuildContext context, bool isBangla) {
    if (crop.infections.isEmpty) {
      return Center(
          child: Text(isBangla
              ? 'কোন রোগ বালাই তথ্য নেই।'
              : 'No infections data entries.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: crop.infections.length,
      itemBuilder: (context, index) {
        final virus = crop.infections[index];
        // ignore: dead_null_aware_expression
        final symptomsText = isBangla
            // ignore: dead_null_aware_expression
            ? (virus.symptomsBn ?? '').trim()
            // ignore: dead_null_aware_expression
            : (virus.symptomsEn ?? '').trim();
        // ignore: dead_null_aware_expression
        final remedyText = isBangla
            // ignore: dead_null_aware_expression
            ? (virus.remedyBn ?? '').trim()
            // ignore: dead_null_aware_expression
            : (virus.remedyEn ?? '').trim();
        final displaySymptoms = symptomsText.isNotEmpty
            ? symptomsText
            : (isBangla
                ? 'কোনো লক্ষণ তথ্য পাওয়া যায়নি।'
                : 'Symptom metrics not registered.');
        final displayRemedy = remedyText.isNotEmpty
            ? remedyText
            : (isBangla
                ? 'কোনো প্রতিকার চিকিৎসা পাওয়া যায়নি।'
                : 'No remedy actions recorded.');

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.bug_report_outlined,
                    color: AppTheme.errorRed, size: 22),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(isBangla ? virus.nameBn : virus.nameEn,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.errorRed))),
              ]),
              const Divider(height: 24, thickness: 0.8),
              Text(isBangla ? 'লক্ষণ সমূহ:' : 'Symptoms:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(displaySymptoms,
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              Text(isBangla ? 'প্রতিকার চিকিৎসা:' : 'Remedy Actions:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.successGreen)),
              const SizedBox(height: 6),
              Text(displayRemedy,
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textSecondary)),
            ]),
          ),
        );
      },
    );
  }
}

class YouTubeEmbeddedPlayer extends StatefulWidget {
  final String videoId;
  const YouTubeEmbeddedPlayer({super.key, required this.videoId});

  @override
  State<YouTubeEmbeddedPlayer> createState() => _YouTubeEmbeddedPlayerState();
}

class _YouTubeEmbeddedPlayerState extends State<YouTubeEmbeddedPlayer> {
  late YoutubePlayerController _controller;
  bool _hasEmbeddingError = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
          useHybridComposition: true),
    )..addListener(_videoPlayerListener);
  }

  void _videoPlayerListener() {
    if ((_controller.value.errorCode == 150 ||
            _controller.value.errorCode == 101) &&
        !_hasEmbeddingError) {
      setState(() => _hasEmbeddingError = true);
    }
  }

  Future<void> _launchExternalVideo() async {
    final Uri url =
        Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoPlayerListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _hasEmbeddingError
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              height: 180,
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      _controller.value.errorCode == 150
                          ? 'নিরাপত্তা সীমাবদ্ধতার কারণে ভিডিওটি অ্যাপে প্লে করা সম্ভব নয়।'
                          : 'ভিডিওটি সরাসরি দেখতে নিচের বাটনে চাপুন',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      onPressed: _launchExternalVideo,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Watch on YouTube',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ]),
            )
          : Container(
              color: Colors.black,
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: AppTheme.primaryGreen,
                progressColors: const ProgressBarColors(
                    playedColor: AppTheme.primaryGreen,
                    handleColor: AppTheme.warningAmber),
              ),
            ),
    );
  }
}
