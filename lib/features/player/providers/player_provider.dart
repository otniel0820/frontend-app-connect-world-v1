import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../services/stream_service.dart';
import '../../../models/stream_info.dart';

final playerProvider = Provider.autoDispose<Player>((ref) {
  final player = Player(
    configuration: const PlayerConfiguration(
      bufferSize: 256 * 1024 * 1024, // 256 MB — streams 4K HEVC de alto bitrate
    ),
  );
  ref.onDispose(player.dispose);
  return player;
});

final videoControllerProvider = Provider.autoDispose<VideoController>((ref) {
  final player = ref.watch(playerProvider);
  return VideoController(
    player,
    // mediacodec_embed usa la superficie Android nativa directamente.
    // Elimina la copia GPU→CPU de mediacodec-copy, que es la causa
    // de que el video 4K vaya lento con audio adelantado.
    configuration: const VideoControllerConfiguration(
      enableHardwareAcceleration: true,
      vo: 'mediacodec_embed',
      hwdec: 'mediacodec',
    ),
  );
});

final streamInfoProvider = FutureProvider.family<StreamInfo, String>((ref, id) async {
  final service = ref.watch(streamServiceProvider);
  return service.getStreamUrl(id);
});
