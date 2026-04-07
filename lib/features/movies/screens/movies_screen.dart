import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/tv_search_bar.dart';
import '../../../models/movie.dart';
import '../providers/movies_provider.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  late final ScrollController _scrollController;
  late final FocusNode _searchFocusNode;
  late final FocusNode _firstChipFocus;
  late final FocusNode _firstCardFocus;
  // One FocusNode per chip (index 0 reuses _firstChipFocus)
  final Map<int, FocusNode> _chipNodes = {};
  final Map<int, GlobalKey> _chipKeys = {};

  FocusNode _chipNode(int index) {
    if (index == 0) return _firstChipFocus;
    return _chipNodes.putIfAbsent(index, () => FocusNode());
  }

  GlobalKey _chipKey(int index) =>
      _chipKeys.putIfAbsent(index, () => GlobalKey());

  void _ensureChipVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _chipKey(index).currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _firstCardFocus = FocusNode();
    _firstChipFocus = FocusNode();
    _searchFocusNode = FocusNode();
    NavbarFocus.registerContentFirst(_firstCardFocus);
  }

  void _onScroll() {
    if (!mounted) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      ref.read(moviesCatalogProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    NavbarFocus.unregisterContentFirst();
    _searchFocusNode.dispose();
    _firstChipFocus.dispose();
    _firstCardFocus.dispose();
    for (final n in _chipNodes.values) { n.dispose(); }
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _jumpToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moviesCatalogProvider);
    final genres = state.genres.keys.toList();

    // Loading inicial
    if (state.isLoading && state.items.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Error sin datos
    if (state.error != null && state.items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error: ${state.error}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(moviesCatalogProvider.notifier).retry(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Sticky header ────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeader(
              height: 128,
              child: Container(
                color: AppColors.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: TvSearchBar(
                        navFocusNode: _searchFocusNode,
                        hintText: 'Buscar película...',
                        onChanged: (v) {
                          ref.read(moviesCatalogProvider.notifier).onSearch(v);
                        },
                        onUp: () => NavbarFocus.requestFocus(),
                        onDown: () => _firstChipFocus.requestFocus(),
                      ),
                    ),
                    SizedBox(
                      height: 46,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: genres.length + 1,
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final genreName =
                              isAll ? 'Todos' : genres[index - 1];
                          final count = isAll
                              ? state.genres.values.fold(0, (a, b) => a + b)
                              : (state.genres[genreName] ?? 0);
                          final selected = isAll
                              ? state.selectedGenre == null
                              : state.selectedGenre == genreName;
                          final totalChips = genres.length + 1;
                          return Padding(
                            key: _chipKey(index),
                            padding: const EdgeInsets.only(right: 8),
                            child: _ChipItem(
                              focusNode: _chipNode(index),
                              label: '$genreName ($count)',
                              selected: selected,
                              onSelected: () {
                                _scrollToTop();
                                ref
                                    .read(moviesCatalogProvider.notifier)
                                    .filterByGenre(isAll ? null : genreName);
                              },
                              onUp: () => _searchFocusNode.requestFocus(),
                              onDown: () {
                                _jumpToTop();
                                _firstCardFocus.requestFocus();
                              },
                              onRight: index < totalChips - 1
                                  ? () {
                                      _chipNode(index + 1).requestFocus();
                                      _ensureChipVisible(index + 1);
                                    }
                                  : null,
                              onLeft: index > 0
                                  ? () {
                                      _chipNode(index - 1).requestFocus();
                                      _ensureChipVisible(index - 1);
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                      child: Text(
                        '${state.items.length} película${state.items.length != 1 ? 's' : ''}${state.hasMore ? '+' : ''}',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Grid ────────────────────────────────────────────────────
          if (state.items.isEmpty && !state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Text('Sin resultados',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.67,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MovieCard(
                    movie: state.items[index],
                    focusNode: index == 0 ? _firstCardFocus : null,
                    isTopRow: index < 5,
                    onUpFromTopRow: () => _firstChipFocus.requestFocus(),
                  ),
                  childCount: state.items.length,
                ),
              ),
            ),

          // ── Loading more / end padding ───────────────────────────────
          SliverToBoxAdapter(
            child: state.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  )
                : const SizedBox(height: 48),
          ),
        ],
      ),
    );
  }
}

// ── Sticky header delegate ────────────────────────────────────────────────────

class _StickyHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  const _StickyHeader({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_StickyHeader old) => true;
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _ChipItem extends StatefulWidget {
  final FocusNode? focusNode;
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback? onRight;
  final VoidCallback? onLeft;

  const _ChipItem({
    this.focusNode,
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.onUp,
    required this.onDown,
    this.onRight,
    this.onLeft,
  });

  @override
  State<_ChipItem> createState() => _ChipItemState();
}

class _ChipItemState extends State<_ChipItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          widget.onSelected();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          widget.onUp();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          widget.onDown();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          widget.onRight?.call();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.onLeft?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focused
                  ? Colors.white
                  : (widget.selected ? AppColors.primary : AppColors.border),
              width: _focused ? 2 : 1,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8)
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              color:
                  widget.selected ? Colors.white : AppColors.textSecondary,
              fontWeight:
                  widget.selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Movie card ────────────────────────────────────────────────────────────────

class _MovieCard extends StatefulWidget {
  final Movie movie;
  final FocusNode? focusNode;
  final VoidCallback? onUpFromTopRow;
  final bool isTopRow;

  const _MovieCard({
    required this.movie,
    this.focusNode,
    this.onUpFromTopRow,
    this.isTopRow = false,
  });

  @override
  State<_MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<_MovieCard> {
  bool _focused = false;

  void _open() => context.push(AppRoutes.detail, extra: {
        'id': widget.movie.id,
        'title': widget.movie.title,
        'posterUrl': widget.movie.posterUrl,
        'backdropUrl': widget.movie.backdropUrl,
        'overview': widget.movie.overview,
        'genre': widget.movie.genre,
        'year': widget.movie.releaseYear,
        'rating': widget.movie.rating,
        'durationMinutes': widget.movie.durationMinutes,
        'isSeries': false,
      });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _open();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
            widget.isTopRow &&
            widget.onUpFromTopRow != null) {
          widget.onUpFromTopRow!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _open,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12)
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.movie.posterUrl?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: widget.movie.posterUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xEE0F1117)],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                    child: Text(
                      widget.movie.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.movie_outlined,
            color: AppColors.textHint, size: 32),
      );
}
