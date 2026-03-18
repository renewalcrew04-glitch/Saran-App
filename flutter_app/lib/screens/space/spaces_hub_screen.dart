import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../models/space_event_model.dart';
import '../../features/space/space_provider_riverpod.dart';
import '../../constants/space_categories.dart';
import '../../features/podcasts/models/podcast_model.dart';
import '../../features/podcasts/services/podcast_service.dart';
import '../../utils/media_utils.dart';
import '../../features/podcasts/screens/podcast_detail_screen.dart';
import '../../features/podcasts/screens/create_podcast_screen.dart';
import '../../features/podcasts/screens/my_podcasts_screen.dart';
import 'my_events_screen.dart';

// ── Brand palette ───────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kDeepIndigo = Color(0xFF1E0E62);
const _kPurple = Color(0xFF7B2D8B);

LinearGradient get _brandGradient => const LinearGradient(
      colors: [_kOrange, _kPurple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

LinearGradient _cardOverlay({double startAlpha = 0.0}) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        _kDeepIndigo.withValues(alpha: 0.55),
        _kDeepIndigo.withValues(alpha: 0.94),
      ],
      stops: const [0.2, 0.58, 1.0],
    );
// ────────────────────────────────────────────────────────────────────────────

class SpacesHubScreen extends StatefulWidget {
  const SpacesHubScreen({super.key});

  @override
  State<SpacesHubScreen> createState() => _SpacesHubScreenState();
}

class _SpacesHubScreenState extends State<SpacesHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEvents = _tab.index == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            floating: true,
            automaticallyImplyLeading: false,
            title: ShaderMask(
              shaderCallback: (r) => _brandGradient.createShader(r),
              blendMode: BlendMode.srcIn,
              child: const Text(
                'Spaces',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  if (isEvents) {
                    context.push('/space/my-events');
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyPodcastsScreen()));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: scheme.outline.withValues(
                            alpha: isDark ? 0.25 : 0.55)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEvents
                            ? Icons.confirmation_number_outlined
                            : Icons.mic_outlined,
                        size: 15,
                        color: scheme.onSurface,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isEvents ? 'My Events' : 'My Podcasts',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Host button — orange gradient with glow
              GestureDetector(
                onTap: () {
                  if (isEvents) {
                    context.push('/space/create');
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreatePodcastScreen()));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: _brandGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: _kOrange.withValues(alpha: 0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: _kOrange.withValues(alpha: 0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Host',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: isDark
                      ? null
                      : Border.all(
                          color: scheme.outline.withValues(alpha: 0.40)),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    gradient: _brandGradient,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'Events'),
                    Tab(text: 'Podcasts'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: const [
            _EventsTab(),
            _PodcastsTab(),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// EVENTS TAB
// ──────────────────────────────────────────────

class _EventsTab extends ConsumerStatefulWidget {
  const _EventsTab();

  @override
  ConsumerState<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<_EventsTab>
    with AutomaticKeepAliveClientMixin {
  String _category = 'All';
  final List<String> _categories = SpaceCategories.all;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(spaceProvider.notifier).load(category: _category));
  }

  void _selectCategory(String cat) {
    if (cat == _category) return;
    setState(() => _category = cat);
    ref.read(spaceProvider.notifier).reset();
    ref.read(spaceProvider.notifier).load(category: cat);
  }

  static String _coverUrl(SpaceEvent e) {
    final base = ApiConfig.networkImageUrl(e.coverUrl!) ?? e.coverUrl!;
    if (e.updatedAt != null) {
      return '$base${base.contains('?') ? '&' : '?'}v=${e.updatedAt!.millisecondsSinceEpoch}';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final events = ref.watch(spaceProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(spaceProvider.notifier).reset();
        await ref.read(spaceProvider.notifier).load(category: _category);
      },
      color: _kOrange,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Category chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = cat == _category;
                  return GestureDetector(
                    onTap: () => _selectCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: selected ? _brandGradient : null,
                        color: selected
                            ? null
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                        border: selected
                            ? null
                            : Border.all(
                                color: scheme.outline.withValues(
                                    alpha: isDark ? 0.25 : 0.60)),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _kOrange.withValues(alpha: 0.30),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : scheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          if (events.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: _brandGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kOrange.withValues(alpha: 0.30),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.event_note_outlined,
                          size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No events yet',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Be the first to host one!',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Section label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: _brandGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Featured',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Featured hero card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EventFeaturedCard(
                  event: events.first,
                  coverUrl: events.first.coverUrl != null &&
                          events.first.coverUrl!.isNotEmpty
                      ? _coverUrl(events.first)
                      : null,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            if (events.length > 1) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: _brandGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upcoming Events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final event = events[i + 1];
                      return _EventGridCard(
                          event: event,
                          coverUrl: event.coverUrl != null &&
                                  event.coverUrl!.isNotEmpty
                              ? _coverUrl(event)
                              : null);
                    },
                    childCount: events.length - 1,
                  ),
                ),
              ),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }
}

class _EventFeaturedCard extends StatelessWidget {
  final SpaceEvent event;
  final String? coverUrl;

  const _EventFeaturedCard({required this.event, this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('EEE, MMM d · h:mm a').format(event.date);

    return GestureDetector(
      onTap: () => context.push('/space/details', extra: event),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover image
              if (coverUrl != null)
                CachedNetworkImage(
                  imageUrl: coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _GradientPlaceholder(
                    icon: Icons.event,
                  ),
                  errorWidget: (_, __, ___) => _GradientPlaceholder(
                    icon: Icons.event,
                  ),
                )
              else
                _GradientPlaceholder(icon: Icons.event),

              // Rich gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: _cardOverlay(),
                ),
              ),

              // Top-right: price badge
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: event.price == 0
                        ? const LinearGradient(
                            colors: [Color(0xFF2ECC71), Color(0xFF27AE60)])
                        : _brandGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (event.price == 0
                                ? const Color(0xFF2ECC71)
                                : _kOrange)
                            .withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    event.price == 0 ? 'Free' : '₹${event.price}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // Bottom content
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      children: [
                        _GradientChip(label: event.category),
                        const SizedBox(width: 6),
                        if (event.isOnline)
                          _GradientChip(
                            label: '🔴 Live Online',
                            solid: const Color(0xFFE53935),
                          ),
                        if (event.isJoined)
                          _GradientChip(
                            label: '✓ Joined',
                            solid: const Color(0xFF43A047),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventGridCard extends StatelessWidget {
  final SpaceEvent event;
  final String? coverUrl;

  const _EventGridCard({required this.event, this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d').format(event.date);

    return GestureDetector(
      onTap: () => context.push('/space/details', extra: event),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed image
            if (coverUrl != null)
              CachedNetworkImage(
                imageUrl: coverUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    _GradientPlaceholder(icon: Icons.event, compact: true),
                errorWidget: (_, __, ___) =>
                    _GradientPlaceholder(icon: Icons.event, compact: true),
              )
            else
              _GradientPlaceholder(icon: Icons.event, compact: true),

            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: _cardOverlay(),
              ),
            ),

            // Joined indicator
            if (event.isJoined)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFF43A047),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),

            // Category badge top-left
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Bottom info overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 10, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          dateStr,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white70),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: event.price == 0
                                ? const LinearGradient(colors: [
                                    Color(0xFF2ECC71),
                                    Color(0xFF27AE60)
                                  ])
                                : _brandGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.price == 0
                                ? 'Free'
                                : '₹${event.price}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// PODCASTS TAB
// ──────────────────────────────────────────────

class _PodcastsTab extends StatefulWidget {
  const _PodcastsTab();

  @override
  State<_PodcastsTab> createState() => _PodcastsTabState();
}

class _PodcastsTabState extends State<_PodcastsTab>
    with AutomaticKeepAliveClientMixin {
  final PodcastService _service = PodcastService();
  List<PodcastModel> _all = [];
  List<PodcastModel> _filtered = [];
  bool _loading = true;
  String? _error;
  String _category = 'All';

  static const List<String> _categories = [
    'All',
    'general',
    'tech',
    'business',
    'health',
    'entertainment',
    'education',
    'other',
  ];

  static const Map<String, String> _categoryLabels = {
    'All': 'All',
    'general': 'General',
    'tech': 'Tech',
    'business': 'Business',
    'health': 'Health',
    'entertainment': 'Entertainment',
    'education': 'Education',
    'other': 'Other',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchPodcasts();
      if (mounted) {
        setState(() {
          _all = list;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is Exception
              ? e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')
              : 'Could not load podcasts.';
        });
      }
    }
  }

  void _applyFilter() {
    if (_category == 'All') {
      _filtered = List.from(_all);
    } else {
      _filtered = _all.where((p) => p.category == _category).toList();
    }
  }

  void _selectCategory(String cat) {
    if (cat == _category) return;
    setState(() {
      _category = cat;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: _kOrange));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: scheme.error),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _kOrange,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Category chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = cat == _category;
                  final label = _categoryLabels[cat] ?? cat;
                  return GestureDetector(
                    onTap: () => _selectCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: selected ? _brandGradient : null,
                        color: selected
                            ? null
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                        border: selected
                            ? null
                            : Border.all(
                                color: scheme.outline.withValues(
                                    alpha: isDark ? 0.25 : 0.60)),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      _kOrange.withValues(alpha: 0.30),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : scheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          if (_filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: _brandGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kOrange.withValues(alpha: 0.30),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.podcasts_outlined,
                          size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No podcasts yet',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start your first podcast!',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Featured label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: _brandGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Featured',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PodcastFeaturedCard(podcast: _filtered.first),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            if (_filtered.length > 1) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: _brandGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'All Podcasts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PodcastGridCard(
                      podcast: _filtered[i + 1],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PodcastDetailScreen(
                              podcast: _filtered[i + 1]),
                        ),
                      ),
                    ),
                    childCount: _filtered.length - 1,
                  ),
                ),
              ),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }
}

class _PodcastFeaturedCard extends StatelessWidget {
  final PodcastModel podcast;

  const _PodcastFeaturedCard({required this.podcast});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PodcastDetailScreen(podcast: podcast)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover
              if (podcast.coverUrl.isNotEmpty)
                safeNetworkImage(
                  url: podcast.coverUrl,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.podcasts,
                )
              else
                _GradientPlaceholder(icon: Icons.podcasts),

              // Overlay
              Container(
                decoration: BoxDecoration(gradient: _cardOverlay()),
              ),

              // Play button top-right
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _brandGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                ),
              ),

              // Bottom content
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GradientChip(
                      label: podcast.category.isNotEmpty
                          ? podcast.category[0].toUpperCase() +
                              podcast.category.substring(1)
                          : 'Podcast',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      podcast.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.headphones_outlined,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(
                          '${podcast.totalEpisodes} episode${podcast.totalEpisodes == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodcastGridCard extends StatelessWidget {
  final PodcastModel podcast;
  final VoidCallback onTap;

  const _PodcastGridCard({required this.podcast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed cover
            if (podcast.coverUrl.isNotEmpty)
              safeNetworkImage(
                url: podcast.coverUrl,
                fit: BoxFit.cover,
                placeholderIcon: Icons.podcasts,
              )
            else
              _GradientPlaceholder(icon: Icons.podcasts, compact: true),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(gradient: _cardOverlay()),
            ),

            // Category badge top-left
            if (podcast.category.isNotEmpty)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: _brandGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    podcast.category[0].toUpperCase() +
                        podcast.category.substring(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // Play button bottom-right
            Positioned(
              bottom: 44,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.40),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 15),
              ),
            ),

            // Bottom info
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      podcast.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.headphones_outlined,
                            size: 11, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          '${podcast.totalEpisodes} ep',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SHARED HELPERS
// ──────────────────────────────────────────────

class _GradientPlaceholder extends StatelessWidget {
  final IconData icon;
  final bool compact;

  const _GradientPlaceholder({required this.icon, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kDeepIndigo,
            _kPurple.withValues(alpha: 0.8),
            _kOrange.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon,
            size: compact ? 36 : 56,
            color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }
}

/// Gradient chip used inside cards (on dark overlays)
class _GradientChip extends StatelessWidget {
  final String label;
  final Color? solid;

  const _GradientChip({required this.label, this.solid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: solid == null ? _brandGradient : null,
        color: solid,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (solid ?? _kOrange).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// Keep _Chip for any external use (backwards compat)
class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
