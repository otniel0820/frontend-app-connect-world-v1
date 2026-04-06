import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import 'content_row.dart';

class ContinueWatchingRow extends StatelessWidget {
  /// Items with their progress (positionMs, durationMs).
  final List<ContinueWatchingItem> items;
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  const ContinueWatchingRow({super.key, required this.items, this.onUp, this.onDown});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Focus(
      skipTraversal: true,
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowUp) {
          (onUp ?? NavbarFocus.requestFocus)();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowDown &&
            onDown != null) {
          onDown!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 14),
            child: Text(
              'Continuar viendo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _ContinueCard(item: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class ContinueWatchingItem {
  final ContentItem content;
  final int positionMs;
  final int durationMs;

  const ContinueWatchingItem({
    required this.content,
    required this.positionMs,
    required this.durationMs,
  });

  /// Effective duration in ms: prefer stored durationMs, fall back to durationMinutes from model.
  int get _effectiveDurationMs {
    if (durationMs > 0) return durationMs;
    final mins = content.durationMinutes;
    if (mins != null && mins > 0) return mins * 60 * 1000;
    return 0;
  }

  double get progress {
    final dur = _effectiveDurationMs;
    return dur > 0 ? (positionMs / dur).clamp(0.0, 1.0) : 0.0;
  }

  bool get hasKnownDuration => _effectiveDurationMs > 0;
}

class _ContinueCard extends StatefulWidget {
  final ContinueWatchingItem item;
  const _ContinueCard({required this.item});

  @override
  State<_ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<_ContinueCard> {
  bool _focused = false;

  String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _openDetail(BuildContext context) {
    context.push(AppRoutes.detail, extra: {
      'id': widget.item.content.id,
      'title': widget.item.content.title,
      'posterUrl': widget.item.content.imageUrl,
      'backdropUrl': widget.item.content.backdropUrl,
      'overview': widget.item.content.overview,
      'genre': widget.item.content.genre,
      'year': widget.item.content.year,
      'rating': widget.item.content.rating,
      'durationMinutes': widget.item.content.durationMinutes,
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.item.progress;
    final hasProgress = widget.item.hasKnownDuration;

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _openDetail(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? AppColors.focusBorder : Colors.transparent,
              width: 2,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with progress bar overlay
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_focused ? 6 : 7),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image — prefer backdrop for landscape feel
                      if ((widget.item.content.backdropUrl ?? '').isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: widget.item.content.backdropUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _poster(),
                        )
                      else if ((widget.item.content.imageUrl ?? '').isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: widget.item.content.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      else
                        _placeholder(),

                      // Dark gradient at bottom
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xDD000000)],
                              stops: [0.45, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Play icon overlay
                      const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white70,
                          size: 38,
                        ),
                      ),

                      // Progress bar at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasProgress)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                                child: Text(
                                  _formatMs(widget.item.positionMs),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              child: LinearProgressIndicator(
                                value: hasProgress ? progress : 0.0,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                                minHeight: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                widget.item.content.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasProgress)
                Text(
                  '${(progress * 100).round()}% visto',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _poster() => CachedNetworkImage(
        imageUrl: widget.item.content.imageUrl ?? '',
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _placeholder(),
      );

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.movie_outlined,
            color: AppColors.textHint, size: 36),
      );
}
