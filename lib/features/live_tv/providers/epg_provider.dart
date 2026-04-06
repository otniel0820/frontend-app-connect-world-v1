import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/epg_item.dart';
import '../../../services/epg_service.dart';

/// Fetch today's EPG for a single channel by its ID.
/// Usage: ref.watch(channelEpgProvider('channel-id'))
final channelEpgProvider =
    FutureProvider.family<List<EpgItem>, String>((ref, channelId) async {
  final service = ref.watch(epgServiceProvider);
  return service.getTodayEpg(channelId: channelId);
});

/// Returns the program currently on air for [channelId], or null if none.
final currentProgramProvider =
    Provider.family<AsyncValue<EpgItem?>, String>((ref, channelId) {
  return ref.watch(channelEpgProvider(channelId)).whenData((programs) {
    final now = DateTime.now();
    try {
      return programs.firstWhere(
        (p) => p.start.isBefore(now) && p.stop.isAfter(now),
      );
    } catch (_) {
      return null;
    }
  });
});
