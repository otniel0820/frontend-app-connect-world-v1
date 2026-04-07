import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage.dart';
import '../providers/player_provider.dart';
import '../widgets/player_controls.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String streamId;
  final String title;
  final int startPositionMs;
  // Optional episode navigation (series only)
  final String? seriesId;
  final List<Map<String, dynamic>>? episodes;
  final int episodeIndex;

  const PlayerScreen({
    super.key,
    required this.streamId,
    required this.title,
    this.startPositionMs = 0,
    this.seriesId,
    this.episodes,
    this.episodeIndex = 0,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _controlsVisible = true;
  Player? _player;
  final _controlsController = PlayerControlsController();

  // Mutable current episode state
  late String _currentStreamId;
  late String _currentTitle;
  late int _currentEpisodeIndex;

  int _capturedDurationMs = 0;

  StreamSubscription<Duration>? _durationSub;
  Timer? _autoSaveTimer;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _currentStreamId = widget.streamId;
    _currentTitle = widget.title;
    _currentEpisodeIndex = widget.episodeIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadStream();
    _scheduleHide();
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _autoSaveTimer?.cancel();
    _hideTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  Future<void> _loadStream({int startMs = 0}) async {
    try {
      _durationSub?.cancel();
      _autoSaveTimer?.cancel();
      _capturedDurationMs = 0;

      final info =
          await ref.read(streamInfoProvider(_currentStreamId).future);
      _player = ref.read(playerProvider);

      // Configurar buffer mpv para streams de alto bitrate (4K/HEVC)
      final native = _player!.platform;
      if (native is NativePlayer) {
        // Network & cache
        await native.setProperty('cache', 'yes');
        await native.setProperty('demuxer-max-bytes', '300MiB');
        await native.setProperty('demuxer-max-back-bytes', '150MiB');
        await native.setProperty('demuxer-readahead-secs', '60');
        await native.setProperty('cache-secs', '60');
        await native.setProperty('network-timeout', '30');
        await native.setProperty('stream-buffer-size', '512KiB');

        // hwdec ya está configurado en VideoControllerConfiguration (mediacodec_embed)
        // No sobreescribir aquí para no entrar en conflicto con el VO de Android

        // Permitir frame drop en decoder y salida — evita congelamiento
        await native.setProperty('framedrop', 'decoder+vo');

        // Audio sync — video se adapta al audio
        await native.setProperty('video-sync', 'audio');
      }

      await _player!.open(Media(info.url));
      if (startMs > 0) {
        await _player!.seek(Duration(milliseconds: startMs));
      }

      _durationSub = _player!.stream.duration.listen((dur) {
        if (dur.inMilliseconds > 0) {
          _capturedDurationMs = dur.inMilliseconds;
        }
      });

      _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _persistProgress();
      });
    } catch (_) {}
  }

  void _persistProgress() {
    final player = _player;
    if (player == null) return;
    final positionMs = player.state.position.inMilliseconds;
    final durationMs = _capturedDurationMs > 0
        ? _capturedDurationMs
        : player.state.duration.inMilliseconds;
    if (positionMs > 30000 &&
        (durationMs == 0 || positionMs < durationMs - 60000)) {
      ref
          .read(localStorageProvider)
          .saveContinueWatching(_currentStreamId, positionMs, durationMs);
    }
  }

  void _closeAndSave() {
    _persistProgress();
    context.pop();
  }

  bool get _hasPrev =>
      widget.episodes != null && _currentEpisodeIndex > 0;

  bool get _hasNext =>
      widget.episodes != null &&
      _currentEpisodeIndex < (widget.episodes!.length - 1);

  Future<void> _navigateEpisode(int delta) async {
    final eps = widget.episodes;
    if (eps == null) return;
    final newIndex = _currentEpisodeIndex + delta;
    if (newIndex < 0 || newIndex >= eps.length) return;

    _persistProgress();

    final ep = eps[newIndex];
    final newId = ep['id'] as String;
    final newTitle = ep['title'] as String;
    final season = ep['season'] as int;

    // Save series last-episode progress
    if (widget.seriesId != null) {
      await ref
          .read(localStorageProvider)
          .saveSeriesLastEpisode(widget.seriesId!, season, newId);
    }

    setState(() {
      _currentEpisodeIndex = newIndex;
      _currentStreamId = newId;
      _currentTitle = newTitle;
    });

    await _loadStream();
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      _closeAndSave();
      return KeyEventResult.handled;
    }

    if (!_controlsVisible) {
      _showControls();
      return KeyEventResult.handled;
    }

    // If a track panel is open, all keys go to the panel handler
    if (_controlsController.isPanelOpen) {
      return _controlsController.handlePanelKey(key);
    }

    // Keep controls visible with auto-hide timer
    _scheduleHide();

    final player = _player;
    if (player == null) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPause) {
      player.playOrPause();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.mediaRewind) {
      final pos = player.state.position;
      player.seek(pos - const Duration(seconds: 10));
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.mediaFastForward) {
      final pos = player.state.position;
      player.seek(pos + const Duration(seconds: 10));
      return KeyEventResult.handled;
    }

    // UP → open audio track panel (if available)
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_controlsController.hasAudio) {
        _controlsController.openAudioPanel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // DOWN → open subtitle panel (if available)
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_controlsController.hasSubtitles) {
        _controlsController.openSubtitlePanel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(videoControllerProvider);
    final streamAsync = ref.watch(streamInfoProvider(_currentStreamId));

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _persistProgress();
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) => _handleKey(event),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: _showControls,
            child: Stack(
              fit: StackFit.expand,
              children: [
                streamAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'No se pudo cargar el contenido',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(
                              streamInfoProvider(_currentStreamId)),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                  data: (_) => Video(controller: controller),
                ),
                if (_controlsVisible)
                  PlayerControls(
                    title: _currentTitle,
                    player: ref.watch(playerProvider),
                    onClose: _closeAndSave,
                    onPrevEpisode: _hasPrev ? () => _navigateEpisode(-1) : null,
                    onNextEpisode: _hasNext ? () => _navigateEpisode(1) : null,
                    controller: _controlsController,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
