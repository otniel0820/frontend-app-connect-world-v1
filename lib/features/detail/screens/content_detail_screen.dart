import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/local_storage.dart';
import '../../../features/series/providers/series_provider.dart';
import '../../../models/series_episode.dart';

class ContentDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;
  const ContentDetailScreen({super.key, required this.args});

  @override
  ConsumerState<ContentDetailScreen> createState() =>
      _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  int? _savedPositionMs;
  int _savedDurationMs = 0;
  int _selectedSeason = 1;
  String? _lastEpisodeId;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() {
    final storage = ref.read(localStorageProvider);
    final id = widget.args['id'] as String;
    final isSeries = widget.args['isSeries'] as bool? ?? false;
    final entry = storage.getContinueWatchingEntry(id);
    setState(() {
      _savedPositionMs = entry?[0];
      _savedDurationMs = entry?[1] ?? 0;
    });
    if (isSeries) {
      final sp = storage.getSeriesLastEpisode(id);
      if (sp != null) {
        setState(() {
          _selectedSeason = sp['season'] as int;
          _lastEpisodeId = sp['episodeId'] as String?;
        });
      }
    }
  }

  Future<void> _playContent({
    int startPositionMs = 0,
    String? episodeId,
    String? episodeTitle,
    int? episodeSeason,
    List<SeriesEpisode>? episodes,
    int episodeIndex = 0,
  }) async {
    final seriesId = widget.args['id'] as String;
    final id = episodeId ?? seriesId;
    final title = episodeTitle ?? widget.args['title'] as String;
    if (episodeId != null && episodeSeason != null) {
      final storage = ref.read(localStorageProvider);
      await storage.saveSeriesLastEpisode(seriesId, episodeSeason, episodeId);
      setState(() => _lastEpisodeId = episodeId);
    }
    if (!mounted) return;
    await context.push(AppRoutes.player, extra: {
      'id': id,
      'title': title,
      'startPositionMs': startPositionMs,
      if (episodes != null) 'seriesId': seriesId,
      if (episodes != null)
        'episodes': episodes
            .map((e) => {
                  'id': e.id,
                  'title': e.title,
                  'season': e.season,
                  'episode': e.episode,
                })
            .toList(),
      if (episodes != null) 'episodeIndex': episodeIndex,
    });
    if (mounted) _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.args['id'] as String;
    final title = widget.args['title'] as String;
    final posterUrl = widget.args['posterUrl'] as String?;
    final backdropUrl = widget.args['backdropUrl'] as String?;
    final overview = widget.args['overview'] as String?;
    final genre = widget.args['genre'] as String?;
    final year = widget.args['year'];
    final rating = widget.args['rating'];
    final durationMinutes = widget.args['durationMinutes'] as int?;
    final isSeries = widget.args['isSeries'] as bool? ?? false;

    final effectiveDurationMs = _savedDurationMs > 0
        ? _savedDurationMs
        : (durationMinutes != null && durationMinutes > 0
            ? durationMinutes * 60 * 1000
            : 0);
    final hasSavedProgress =
        _savedPositionMs != null && _savedPositionMs! > 30000;

    final bgImage = (backdropUrl?.isNotEmpty == true)
        ? backdropUrl!
        : (posterUrl?.isNotEmpty == true ? posterUrl! : null);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ─────────────────────────────────────────
          if (bgImage != null)
            CachedNetworkImage(
              imageUrl: bgImage,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: AppColors.surface),
            )
          else
            Container(color: AppColors.surface),

          // Bottom-to-top dark gradient
          const DecoratedBox(
            decoration:
                BoxDecoration(gradient: AppColors.bannerGradient),
          ),

          // Left-to-right dark gradient (makes text readable)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.30),
                ],
                stops: const [0.0, 0.65],
              ),
            ),
          ),

          // ── Foreground (fixed, no scroll) ─────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                _BackBtn(onTap: () => context.pop()),

                // Main info area — fixed height for series, expanded for movies
                Builder(builder: (context) {
                  final infoWidget = Padding(
                    padding: const EdgeInsets.fromLTRB(40, 8, 40, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Poster thumbnail
                        if (posterUrl != null && posterUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: posterUrl,
                              width: 120,
                              height: 178,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 120,
                                height: 178,
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.movie_outlined,
                                    color: AppColors.textHint, size: 36),
                              ),
                            ),
                          ),
                        const SizedBox(width: 28),
                        // Info column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                children: [
                                  if (year != null && year != 0)
                                    _MetaChip(
                                        icon: Icons.calendar_today_outlined,
                                        label: year.toString()),
                                  if (genre != null && genre.isNotEmpty)
                                    _MetaChip(
                                        icon: Icons.category_outlined,
                                        label: genre),
                                  if (rating != null && rating != 0)
                                    _MetaChip(
                                      icon: Icons.star_outline,
                                      label: rating is double
                                          ? rating.toStringAsFixed(1)
                                          : rating.toString(),
                                      color: const Color(0xFFFBBF24),
                                    ),
                                  if (!isSeries &&
                                      durationMinutes != null &&
                                      durationMinutes > 0)
                                    _MetaChip(
                                        icon: Icons.schedule_outlined,
                                        label: '$durationMinutes min'),
                                  if (isSeries)
                                    const _MetaChip(
                                        icon: Icons.tv_outlined,
                                        label: 'Serie'),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (overview != null && overview.isNotEmpty)
                                Text(
                                  overview,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                  maxLines: isSeries ? 2 : 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 20),
                              // Play buttons — movies only
                              if (!isSeries) ...[
                                if (hasSavedProgress) ...[
                                  _ProgressBar(
                                    positionMs: _savedPositionMs!,
                                    durationMs: effectiveDurationMs,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                Row(
                                  children: [
                                    _ActionBtn(
                                      icon: hasSavedProgress
                                          ? Icons.play_circle_outline
                                          : Icons.play_arrow,
                                      label: hasSavedProgress
                                          ? 'Continuar — ${_formatMs(_savedPositionMs!)}'
                                          : 'Reproducir',
                                      autofocus: true,
                                      onTap: () => _playContent(
                                        startPositionMs: hasSavedProgress
                                            ? _savedPositionMs!
                                            : 0,
                                      ),
                                    ),
                                    if (hasSavedProgress) ...[
                                      const SizedBox(width: 12),
                                      _ActionBtn(
                                        icon: Icons.replay,
                                        label: 'Desde el inicio',
                                        outlined: true,
                                        onTap: () => _playContent(
                                            startPositionMs: 0),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  if (!isSeries) return Expanded(child: infoWidget);
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.46,
                    child: infoWidget,
                  );
                }),

                // ── Episode section (series only, fills remaining space) ──
                if (isSeries)
                  Expanded(
                    child: _SeriesEpisodesSection(
                      seriesId: id,
                      seriesTitle: title,
                      selectedSeason: _selectedSeason,
                      lastEpisodeId: _lastEpisodeId,
                      onSeasonChanged: (s) =>
                          setState(() => _selectedSeason = s),
                      onPlayEpisode: (ep, startMs, allEps, idx) =>
                          _playContent(
                        episodeId: ep.id,
                        episodeTitle:
                            '$title T${ep.season}E${ep.episode} — ${ep.title}',
                        episodeSeason: ep.season,
                        startPositionMs: startMs,
                        episodes: allEps,
                        episodeIndex: idx,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMs(int ms) {
    final total = Duration(milliseconds: ms);
    final h = total.inHours;
    final m =
        total.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
        total.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ── Back button ─────────────────────────────────────────────────────────────

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Focus(
        autofocus: true,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _focused
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused ? AppColors.focusBorder : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text('Volver',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action button (play / resume / replay) ──────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool outlined;
  final bool autofocus;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.autofocus = false,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.outlined
                ? (_focused
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.transparent)
                : (_focused ? AppColors.primaryLight : AppColors.primary),
            borderRadius: BorderRadius.circular(8),
            border: widget.outlined
                ? Border.all(
                    color: _focused ? AppColors.focusBorder : Colors.white54)
                : (_focused
                    ? Border.all(color: AppColors.focusBorder, width: 2)
                    : null),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Series episodes section (vertical list, dropdown season) ─────────────────

class _SeriesEpisodesSection extends ConsumerStatefulWidget {
  final String seriesId;
  final String seriesTitle;
  final int selectedSeason;
  final String? lastEpisodeId;
  final ValueChanged<int> onSeasonChanged;
  final void Function(
      SeriesEpisode ep,
      int startPositionMs,
      List<SeriesEpisode> allEps,
      int episodeIndex) onPlayEpisode;

  const _SeriesEpisodesSection({
    required this.seriesId,
    required this.seriesTitle,
    required this.selectedSeason,
    required this.onSeasonChanged,
    required this.onPlayEpisode,
    this.lastEpisodeId,
  });

  @override
  ConsumerState<_SeriesEpisodesSection> createState() =>
      _SeriesEpisodesSectionState();
}

class _SeriesEpisodesSectionState
    extends ConsumerState<_SeriesEpisodesSection> {
  @override
  Widget build(BuildContext context) {
    final episodesAsync =
        ref.watch(seriesEpisodesProvider(widget.seriesId));
    final storage = ref.read(localStorageProvider);

    return episodesAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: 32),
            const SizedBox(height: 8),
            const Text('No se pudieron cargar los episodios',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(e.toString(),
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 11),
                maxLines: 2),
          ],
        ),
      ),
      data: (episodes) {
        if (episodes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Center(
                child: Text('No hay episodios disponibles',
                    style:
                        TextStyle(color: AppColors.textSecondary))),
          );
        }

        final seasons = <int>{};
        for (final ep in episodes) { seasons.add(ep.season); }
        final sortedSeasons = seasons.toList()..sort();
        final activeSeason = sortedSeasons.contains(widget.selectedSeason)
            ? widget.selectedSeason
            : sortedSeasons.first;
        final seasonEps = episodes
            .where((ep) => ep.season == activeSeason)
            .toList()
          ..sort((a, b) => a.episode.compareTo(b.episode));

        // Autofocus the last-watched episode (or first if none)
        final autofocusId = widget.lastEpisodeId != null &&
                seasonEps.any((e) => e.id == widget.lastEpisodeId)
            ? widget.lastEpisodeId
            : seasonEps.first.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Episodios" title + season dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 4, 40, 8),
              child: Row(
                children: [
                  const Text('Episodios',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(width: 16),
                  _SeasonDropdown(
                    seasons: sortedSeasons,
                    selected: activeSeason,
                    onChanged: widget.onSeasonChanged,
                  ),
                ],
              ),
            ),

            // Vertical episode list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 8),
                itemCount: seasonEps.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final ep = seasonEps[i];
                  final progress =
                      storage.getContinueWatchingEntry(ep.id);
                  final positionMs =
                      (progress != null && progress[0] > 30000)
                          ? progress[0]
                          : 0;
                  final durationMs = progress?[1] ?? 0;
                  return _EpisodeRow(
                    episode: ep,
                    autofocus: ep.id == autofocusId,
                    isLastWatched: ep.id == widget.lastEpisodeId,
                    positionMs: positionMs,
                    durationMs: durationMs,
                    onPlay: () =>
                        widget.onPlayEpisode(ep, positionMs, seasonEps, i),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Season dropdown ───────────────────────────────────────────────────────────

class _SeasonDropdown extends StatefulWidget {
  final List<int> seasons;
  final int selected;
  final ValueChanged<int> onChanged;
  const _SeasonDropdown(
      {required this.seasons,
      required this.selected,
      required this.onChanged});

  @override
  State<_SeasonDropdown> createState() => _SeasonDropdownState();
}

class _SeasonDropdownState extends State<_SeasonDropdown> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          _showPicker(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => _showPicker(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _focused
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? AppColors.focusBorder : AppColors.border,
              width: _focused ? 2 : 1,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Temporada ${widget.selected}',
                style: TextStyle(
                  color: _focused ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _focused ? Colors.white : AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showDialog<int>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280, maxHeight: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.seasons.map((s) {
                final isSelected = s == widget.selected;
                return _DialogItem(
                  label: 'Temporada $s',
                  isSelected: isSelected,
                  autofocus: isSelected,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onChanged(s);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Episode row (vertical list item) ─────────────────────────────────────────

class _EpisodeRow extends StatefulWidget {
  final SeriesEpisode episode;
  final bool autofocus;
  final bool isLastWatched;
  final int positionMs;
  final int durationMs;
  final VoidCallback onPlay;

  const _EpisodeRow({
    required this.episode,
    required this.onPlay,
    this.autofocus = false,
    this.isLastWatched = false,
    this.positionMs = 0,
    this.durationMs = 0,
  });

  @override
  State<_EpisodeRow> createState() => _EpisodeRowState();
}

class _EpisodeRowState extends State<_EpisodeRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ep = widget.episode;
    final hasProgress = widget.positionMs > 0 && widget.durationMs > 0;
    final progress = hasProgress
        ? (widget.positionMs / widget.durationMs).clamp(0.0, 1.0)
        : 0.0;

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          widget.onPlay();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 90,
          decoration: BoxDecoration(
            color: _focused
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused
                  ? AppColors.focusBorder
                  : (widget.isLastWatched
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.transparent),
              width: _focused ? 2 : 1,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(7)),
                child: SizedBox(
                  width: 140,
                  height: 90,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ep.coverUrl != null && ep.coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ep.coverUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _thumb(),
                            )
                          : _thumb(),
                      // Play icon — always visible but subtle; prominent on focus
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black
                                .withValues(alpha: _focused ? 0.55 : 0.35),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white
                                .withValues(alpha: _focused ? 1.0 : 0.8),
                            size: 26,
                          ),
                        ),
                      ),
                      // Progress bar on thumbnail bottom
                      if (hasProgress)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Episode info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'E${ep.episode}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (ep.durationLabel.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              ep.durationLabel,
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (widget.isLastWatched) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.6)),
                              ),
                              child: const Text(
                                'Continuar',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ep.title,
                        style: TextStyle(
                          color: _focused
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.movie_outlined,
            color: AppColors.textHint, size: 28),
      );
}

// ── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int positionMs;
  final int durationMs;
  const _ProgressBar({required this.positionMs, this.durationMs = 0});

  @override
  Widget build(BuildContext context) {
    final progress =
        (durationMs > 0) ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;
    final pct =
        durationMs > 0 ? ' (${(progress * 100).round()}%)' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visto hasta ${_formatMs(positionMs)}$pct',
          style:
              const TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  String _formatMs(int ms) {
    final total = Duration(milliseconds: ms);
    final h = total.inHours;
    final m =
        total.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
        total.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ── Dialog item (D-pad focusable) ────────────────────────────────────────────

class _DialogItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool autofocus;
  final VoidCallback onTap;

  const _DialogItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<_DialogItem> createState() => _DialogItemState();
}

class _DialogItemState extends State<_DialogItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _focused
              ? AppColors.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check, color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Meta chip ────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: c, fontSize: 13)),
      ],
    );
  }
}
