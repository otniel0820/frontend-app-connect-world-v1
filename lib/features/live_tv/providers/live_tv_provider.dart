import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/channel.dart';
import '../../../services/xtream_service.dart';

/// All live channels — backed by the shared raw provider (cached).
final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  return ref.watch(rawLiveStreamsProvider.future);
});

final channelGroupsProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(channelsProvider).whenData(
        (channels) => channels
            .map((c) =>
                c.groupTitle?.isNotEmpty == true ? c.groupTitle! : 'General')
            .toSet()
            .toList()
          ..sort(),
      );
});

final channelsByGroupProvider =
    Provider<AsyncValue<Map<String, List<Channel>>>>((ref) {
  return ref.watch(channelsProvider).whenData((channels) {
    final map = <String, List<Channel>>{};
    for (final c in channels) {
      final group =
          c.groupTitle?.isNotEmpty == true ? c.groupTitle! : 'General';
      map.putIfAbsent(group, () => []).add(c);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  });
});
