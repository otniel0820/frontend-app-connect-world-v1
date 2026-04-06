import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

import '../../../core/theme/app_colors.dart';

// ── Track entry model ─────────────────────────────────────────────────────────

class _TrackEntry {
  final String label;
  final bool isActive;
  const _TrackEntry({required this.label, required this.isActive});
}

// ── Controller (lets PlayerScreen open panels via D-pad) ──────────────────────

class PlayerControlsController {
  void Function()? _openAudio;
  void Function()? _openSubtitles;
  void Function()? _closePanelFn;
  KeyEventResult Function(LogicalKeyboardKey)? _panelKeyHandler;
  bool _hasAudio = false;
  bool _hasSubtitles = false;
  bool _isPanelOpen = false;

  bool get hasAudio => _hasAudio;
  bool get hasSubtitles => _hasSubtitles;
  bool get isPanelOpen => _isPanelOpen;

  void openAudioPanel() => _openAudio?.call();
  void openSubtitlePanel() => _openSubtitles?.call();
  void closePanel() => _closePanelFn?.call();

  /// Called by PlayerScreen when isPanelOpen is true.
  KeyEventResult handlePanelKey(LogicalKeyboardKey key) =>
      _panelKeyHandler?.call(key) ?? KeyEventResult.ignored;
}

// ── Public widget ─────────────────────────────────────────────────────────────

class PlayerControls extends StatefulWidget {
  final String title;
  final Player player;
  final VoidCallback onClose;
  final VoidCallback? onPrevEpisode;
  final VoidCallback? onNextEpisode;
  final PlayerControlsController? controller;

  const PlayerControls({
    super.key,
    required this.title,
    required this.player,
    required this.onClose,
    this.onPrevEpisode,
    this.onNextEpisode,
    this.controller,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  // Playback state
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Track state (populated once stream loads)
  Tracks _tracks = const Tracks();
  Track _currentTrack = const Track();

  // Panel state
  bool _showAudioPanel = false;
  bool _showSubtitlePanel = false;
  int _audioPanelIdx = 0;
  int _subtitlePanelIdx = 0;

  // Stream subscriptions
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Tracks>? _tracksSub;
  StreamSubscription<Track>? _trackSub;

  @override
  void initState() {
    super.initState();
    // Register callbacks with controller so PlayerScreen can trigger them
    widget.controller?._openAudio = _openAudioPanel;
    widget.controller?._openSubtitles = _openSubtitlePanel;
    widget.controller?._closePanelFn = _closePanel;
    _playingSub = widget.player.stream.playing.listen((v) {
      if (mounted) setState(() => _playing = v);
    });
    _positionSub = widget.player.stream.position.listen((v) {
      if (mounted) setState(() => _position = v);
    });
    _durationSub = widget.player.stream.duration.listen((v) {
      if (mounted) setState(() => _duration = v);
    });
    _tracksSub = widget.player.stream.tracks.listen((t) {
      if (mounted) {
        setState(() => _tracks = t);
        // Keep controller informed so PlayerScreen knows what's available
        if (widget.controller != null) {
          widget.controller!._hasAudio = t.audio.length > 1;
          widget.controller!._hasSubtitles = t.subtitle.isNotEmpty;
        }
      }
    });
    _trackSub = widget.player.stream.track.listen((t) {
      if (mounted) setState(() => _currentTrack = t);
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _tracksSub?.cancel();
    _trackSub?.cancel();
    widget.controller?._openAudio = null;
    widget.controller?._openSubtitles = null;
    widget.controller?._closePanelFn = null;
    widget.controller?._panelKeyHandler = null;
    widget.controller?._isPanelOpen = false;
    super.dispose();
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ── Panel open/close ────────────────────────────────────────────────────────

  void _openAudioPanel() {
    final idx = _tracks.audio.indexWhere((t) => t.id == _currentTrack.audio.id);
    if (widget.controller != null) {
      widget.controller!._isPanelOpen = true;
      widget.controller!._panelKeyHandler = _handlePanelKey;
    }
    setState(() {
      _showAudioPanel = true;
      _showSubtitlePanel = false;
      _audioPanelIdx = idx >= 0 ? idx : 0;
    });
  }

  void _openSubtitlePanel() {
    final idx =
        _tracks.subtitle.indexWhere((t) => t.id == _currentTrack.subtitle.id);
    if (widget.controller != null) {
      widget.controller!._isPanelOpen = true;
      widget.controller!._panelKeyHandler = _handlePanelKey;
    }
    setState(() {
      _showSubtitlePanel = true;
      _showAudioPanel = false;
      // index 0 = "Sin subtítulos", index 1+ = actual tracks
      _subtitlePanelIdx = idx >= 0 ? idx + 1 : 0;
    });
  }

  void _closePanel() {
    if (widget.controller != null) {
      widget.controller!._isPanelOpen = false;
      widget.controller!._panelKeyHandler = null;
    }
    setState(() {
      _showAudioPanel = false;
      _showSubtitlePanel = false;
    });
  }

  // ── Panel key handler (called directly by PlayerScreen via controller) ────────

  KeyEventResult _handlePanelKey(LogicalKeyboardKey key) {
    // Back → close panel
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      _closePanel();
      return KeyEventResult.handled;
    }

    if (_showAudioPanel) {
      final tracks = _tracks.audio;
      if (key == LogicalKeyboardKey.arrowUp) {
        setState(() => _audioPanelIdx = max(0, _audioPanelIdx - 1));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        setState(
            () => _audioPanelIdx = min(tracks.length - 1, _audioPanelIdx + 1));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        if (_audioPanelIdx < tracks.length) {
          widget.player.setAudioTrack(tracks[_audioPanelIdx]);
        }
        _closePanel();
        return KeyEventResult.handled;
      }
    }

    if (_showSubtitlePanel) {
      final tracks = _tracks.subtitle;
      final count = tracks.length + 1; // 0 = no subtitles
      if (key == LogicalKeyboardKey.arrowUp) {
        setState(() => _subtitlePanelIdx = max(0, _subtitlePanelIdx - 1));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        setState(
            () => _subtitlePanelIdx = min(count - 1, _subtitlePanelIdx + 1));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        if (_subtitlePanelIdx == 0) {
          widget.player.setSubtitleTrack(SubtitleTrack.no());
        } else {
          widget.player.setSubtitleTrack(tracks[_subtitlePanelIdx - 1]);
        }
        _closePanel();
        return KeyEventResult.handled;
      }
    }

    // Block any other key from reaching the player while panel is open
    return KeyEventResult.handled;
  }

  // ── Track label helpers ─────────────────────────────────────────────────────

  String _audioLabel(AudioTrack t, int i) {
    final lang = t.language?.trim();
    final title = t.title?.trim();
    if (lang != null && lang.isNotEmpty) return lang.toUpperCase();
    if (title != null && title.isNotEmpty) return title;
    return 'Pista ${i + 1}';
  }

  String _subtitleLabel(SubtitleTrack t, int i) {
    final lang = t.language?.trim();
    final title = t.title?.trim();
    if (lang != null && lang.isNotEmpty) return lang.toUpperCase();
    if (title != null && title.isNotEmpty) return title;
    return 'Subtítulo ${i + 1}';
  }

  List<_TrackEntry> get _audioEntries {
    return _tracks.audio.asMap().entries.map((e) => _TrackEntry(
          label: _audioLabel(e.value, e.key),
          isActive: e.value.id == _currentTrack.audio.id,
        )).toList();
  }

  List<_TrackEntry> get _subtitleEntries {
    return [
      _TrackEntry(
        label: 'Sin subtítulos',
        isActive: _currentTrack.subtitle.id == 'no',
      ),
      ..._tracks.subtitle.asMap().entries.map((e) => _TrackEntry(
            label: _subtitleLabel(e.value, e.key),
            isActive: e.value.id == _currentTrack.subtitle.id,
          )),
    ];
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasPrevNext =
        widget.onPrevEpisode != null || widget.onNextEpisode != null;
    final hasAudio = _tracks.audio.length > 1;
    final hasSubtitles = _tracks.subtitle.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Gradient + controls ────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC000000),
                Colors.transparent,
                Colors.transparent,
                Color(0xCC000000),
              ],
              stops: [0.0, 0.2, 0.8, 1.0],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onClose,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasAudio) ...[
                      const SizedBox(width: 4),
                      _TopBarButton(
                        icon: Icons.audiotrack_rounded,
                        tooltip: 'Audio',
                        isActive: _showAudioPanel,
                        onPressed: () =>
                            _showAudioPanel ? _closePanel() : _openAudioPanel(),
                      ),
                    ],
                    if (hasSubtitles) ...[
                      const SizedBox(width: 4),
                      _TopBarButton(
                        icon: Icons.subtitles_rounded,
                        tooltip: 'Subtítulos',
                        isActive: _showSubtitlePanel,
                        onPressed: () => _showSubtitlePanel
                            ? _closePanel()
                            : _openSubtitlePanel(),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_duration.inSeconds > 0) ...[
                      Slider(
                        value: _position.inSeconds
                            .clamp(0, _duration.inSeconds)
                            .toDouble(),
                        min: 0,
                        max: _duration.inSeconds.toDouble(),
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.white30,
                        onChanged: (v) => widget.player
                            .seek(Duration(seconds: v.toInt())),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_format(_position),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(_format(_duration),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasPrevNext)
                          IconButton(
                            icon: Icon(Icons.skip_previous_rounded,
                                color: widget.onPrevEpisode != null
                                    ? Colors.white
                                    : Colors.white30,
                                size: 32),
                            onPressed: widget.onPrevEpisode,
                            tooltip: 'Episodio anterior',
                          ),
                        if (hasPrevNext) const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.replay_10,
                              color: Colors.white, size: 32),
                          onPressed: () => widget.player
                              .seek(_position - const Duration(seconds: 10)),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _playing ? Icons.pause : Icons.play_arrow,
                              color: Colors.black,
                              size: 36,
                            ),
                            onPressed: widget.player.playOrPause,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.forward_10,
                              color: Colors.white, size: 32),
                          onPressed: () => widget.player
                              .seek(_position + const Duration(seconds: 10)),
                        ),
                        if (hasPrevNext) const SizedBox(width: 4),
                        if (hasPrevNext)
                          IconButton(
                            icon: Icon(Icons.skip_next_rounded,
                                color: widget.onNextEpisode != null
                                    ? Colors.white
                                    : Colors.white30,
                                size: 32),
                            onPressed: widget.onNextEpisode,
                            tooltip: 'Siguiente episodio',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Track panels (open on demand) ──────────────────────────────────
        if (_showAudioPanel)
          _TrackPanel(
            title: 'Audio',
            entries: _audioEntries,
            focusedIndex: _audioPanelIdx,
          ),
        if (_showSubtitlePanel)
          _TrackPanel(
            title: 'Subtítulos',
            entries: _subtitleEntries,
            focusedIndex: _subtitlePanelIdx,
          ),
      ],
    );
  }
}

// ── Track panel overlay ───────────────────────────────────────────────────────

class _TrackPanel extends StatelessWidget {
  final String title;
  final List<_TrackEntry> entries;
  final int focusedIndex;

  const _TrackPanel({
    required this.title,
    required this.entries,
    required this.focusedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 64,
      right: 16,
      width: 250,
      child: Material(
        color: Colors.transparent,
        child: Container(
            constraints: const BoxConstraints(maxHeight: 380),
            decoration: BoxDecoration(
              color: const Color(0xF01A1C24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 9),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final isFocused = i == focusedIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: isFocused
                              ? AppColors.primary.withValues(alpha: 0.22)
                              : Colors.transparent,
                          border: isFocused
                              ? const Border(
                                  left: BorderSide(
                                      color: AppColors.primary, width: 3))
                              : const Border(
                                  left: BorderSide(
                                      color: Colors.transparent, width: 3)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              child: e.isActive
                                  ? const Icon(Icons.check,
                                      color: AppColors.primary, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.label,
                                style: TextStyle(
                                  color:
                                      isFocused ? Colors.white : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: isFocused
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
    );
  }
}

// ── Top bar icon button with focus highlight ──────────────────────────────────

class _TopBarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  const _TopBarButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  @override
  State<_TopBarButton> createState() => _TopBarButtonState();
}

class _TopBarButtonState extends State<_TopBarButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (_focused ? Colors.white24 : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused ? Colors.white : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              widget.icon,
              color: widget.isActive ? AppColors.primary : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
