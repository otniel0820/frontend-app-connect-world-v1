import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/local_storage.dart';
import '../providers/home_provider.dart';
import '../widgets/featured_banner.dart';
import '../widgets/content_row.dart';
import '../widgets/continue_watching_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _cwScope = FocusScopeNode();
  final _moviesScope = FocusScopeNode();
  final _seriesScope = FocusScopeNode();
  final _liveTVScope = FocusScopeNode();

  final _moviesFirstCard = FocusNode();
  final _seriesFirstCard = FocusNode();
  final _liveTVFirstCard = FocusNode();

  final _scrollController = ScrollController();
  final _moviesKey = GlobalKey();
  final _seriesKey = GlobalKey();
  final _liveTVKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _registerNavbarDown();
    });
    _moviesFirstCard.addListener(_onMoviesFocus);
    _seriesFirstCard.addListener(_onSeriesFocus);
    _liveTVFirstCard.addListener(_onLiveTVFocus);
  }

  void _registerNavbarDown() {
    NavbarFocus.registerContentFirst(_moviesFirstCard);
  }

  void _onMoviesFocus() {
    if (_moviesFirstCard.hasFocus) _ensureVisible(_moviesKey);
  }

  void _onSeriesFocus() {
    if (_seriesFirstCard.hasFocus) _ensureVisible(_seriesKey);
  }

  void _onLiveTVFocus() {
    if (_liveTVFirstCard.hasFocus) _ensureVisible(_liveTVKey);
  }

  void _ensureVisible(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.0,
        );
      }
    });
  }

  @override
  void dispose() {
    NavbarFocus.unregisterContentFirst();
    _moviesFirstCard.removeListener(_onMoviesFocus);
    _seriesFirstCard.removeListener(_onSeriesFocus);
    _liveTVFirstCard.removeListener(_onLiveTVFocus);
    _cwScope.dispose();
    _moviesScope.dispose();
    _seriesScope.dispose();
    _liveTVScope.dispose();
    _moviesFirstCard.dispose();
    _seriesFirstCard.dispose();
    _liveTVFirstCard.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);
    final storage = ref.read(localStorageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: catalogAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load content',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(catalogProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (catalog) {
          final cwMap = storage.getContinueWatching();
          final allItems = [
            ...catalog.movies.map((m) => ContentItem(
                  id: m.id, title: m.title,
                  imageUrl: m.posterUrl, backdropUrl: m.backdropUrl,
                  overview: m.overview, genre: m.genre,
                  year: m.releaseYear, rating: m.rating,
                  durationMinutes: m.durationMinutes,
                )),
            ...catalog.series.map((s) => ContentItem(
                  id: s.id, title: s.title,
                  imageUrl: s.posterUrl, backdropUrl: s.backdropUrl,
                  overview: s.overview, genre: s.genre,
                  year: s.releaseYear, rating: s.rating,
                  isSeries: true,
                )),
          ];
          final continueItems = allItems
              .where((i) => cwMap.containsKey(i.id))
              .map((i) {
                final entry = storage.getContinueWatchingEntry(i.id);
                return ContinueWatchingItem(
                  content: i,
                  positionMs: entry?[0] ?? cwMap[i.id]!,
                  durationMs: entry?[1] ?? 0,
                );
              })
              .toList();

          final hasCW = continueItems.isNotEmpty;
          final hasMovies = catalog.movies.isNotEmpty;
          final hasSeries = catalog.series.isNotEmpty;

          final hasLiveTV = catalog.channels.isNotEmpty;

          // Build each section's onUp: point to the nearest non-empty section above.
          // ContinueWatchingRow has no "Ver todo" button so _cwScope.requestFocus()
          // correctly lands on its first card — no special node needed there.
          VoidCallback moviesOnUp =
              hasCW ? () => _cwScope.requestFocus() : NavbarFocus.requestFocus;

          VoidCallback seriesOnUp = hasMovies
              ? () => _moviesFirstCard.requestFocus()
              : (hasCW ? () => _cwScope.requestFocus() : NavbarFocus.requestFocus);

          VoidCallback liveTVOnUp = hasSeries
              ? () => _seriesFirstCard.requestFocus()
              : (hasMovies
                  ? () => _moviesFirstCard.requestFocus()
                  : (hasCW ? () => _cwScope.requestFocus() : NavbarFocus.requestFocus));

          // Build each section's onDown: use first-card FocusNodes so D-pad DOWN
          // skips the "Ver todo" button and lands directly on the first content card.
          VoidCallback? cwOnDown = hasMovies
              ? () => _moviesFirstCard.requestFocus()
              : (hasSeries
                  ? () => _seriesFirstCard.requestFocus()
                  : (hasLiveTV ? () => _liveTVFirstCard.requestFocus() : null));

          VoidCallback? moviesOnDown = hasSeries
              ? () => _seriesFirstCard.requestFocus()
              : (hasLiveTV ? () => _liveTVFirstCard.requestFocus() : null);

          VoidCallback? seriesOnDown =
              hasLiveTV ? () => _liveTVFirstCard.requestFocus() : null;

          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (catalog.featured.isNotEmpty)
                  FeaturedBanner(movie: catalog.featured.first),
                if (hasCW)
                  FocusScope(
                    node: _cwScope,
                    child: ContinueWatchingRow(
                      items: continueItems,
                      onUp: NavbarFocus.requestFocus,
                      onDown: cwOnDown,
                    ),
                  ),
                if (hasMovies)
                  KeyedSubtree(
                    key: _moviesKey,
                    child: FocusScope(
                      node: _moviesScope,
                      child: ContentRow(
                        title: 'Películas HD · 4K',
                        items: catalog.movies
                            .map((m) => ContentItem(
                                  id: m.id, title: m.title,
                                  imageUrl: m.posterUrl,
                                  backdropUrl: m.backdropUrl,
                                  overview: m.overview, genre: m.genre,
                                  year: m.releaseYear, rating: m.rating,
                                  durationMinutes: m.durationMinutes,
                                ))
                            .toList(),
                        onSeeAll: () => context.push(AppRoutes.movies),
                        onUp: moviesOnUp,
                        onDown: moviesOnDown,
                        firstCardFocusNode: _moviesFirstCard,
                      ),
                    ),
                  ),
                if (hasSeries)
                  KeyedSubtree(
                    key: _seriesKey,
                    child: FocusScope(
                      node: _seriesScope,
                      child: ContentRow(
                        title: 'Series HD · 4K',
                        items: catalog.series
                            .map((s) => ContentItem(
                                  id: s.id, title: s.title,
                                  imageUrl: s.posterUrl,
                                  backdropUrl: s.backdropUrl,
                                  overview: s.overview, genre: s.genre,
                                  year: s.releaseYear, rating: s.rating,
                                  isSeries: true,
                                ))
                            .toList(),
                        onSeeAll: () => context.push(AppRoutes.series),
                        onUp: seriesOnUp,
                        onDown: seriesOnDown,
                        firstCardFocusNode: _seriesFirstCard,
                      ),
                    ),
                  ),
                if (hasLiveTV)
                  KeyedSubtree(
                    key: _liveTVKey,
                    child: FocusScope(
                      node: _liveTVScope,
                      child: ContentRow(
                        title: 'En Vivo',
                        items: catalog.channels
                            .map((c) => ContentItem(
                                  id: c.id,
                                  title: c.name,
                                  imageUrl: c.logoUrl,
                                ))
                            .toList(),
                        onSeeAll: () => context.push(AppRoutes.liveTV),
                        onUp: liveTVOnUp,
                        firstCardFocusNode: _liveTVFirstCard,
                      ),
                    ),
                  ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }
}
