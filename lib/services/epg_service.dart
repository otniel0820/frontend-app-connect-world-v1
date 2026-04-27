import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/epg_item.dart';
import 'xtream_service.dart';

final epgServiceProvider = Provider<EpgService>((ref) {
  return EpgService(ref.watch(xtreamServiceProvider));
});

class EpgService {
  final XtreamService _xtream;

  EpgService(this._xtream);

  /// Returns short EPG for a live channel.
  /// [channelId] must be the encoded ID (e.g., "live:12345").
  Future<List<EpgItem>> getShortEpg({
    required String channelId,
    int limit = 4,
  }) async {
    final parts = channelId.split(':');
    final streamId = parts.length >= 2 ? parts[1] : channelId;

    final listings = await _xtream.getShortEpg(streamId, limit: limit);

    return listings.map((e) {
      DateTime? start;
      DateTime? stop;
      try {
        start = DateTime.parse(e['start']?.toString() ?? '');
      } catch (_) {}
      try {
        stop = DateTime.parse(
            e['end']?.toString() ?? e['stop']?.toString() ?? '');
      } catch (_) {}

      return EpgItem(
        channelId: channelId,
        title: _decodeTitle(e['title']?.toString() ?? ''),
        description: e['description']?.toString(),
        start: start ?? DateTime.now(),
        stop: stop ?? DateTime.now().add(const Duration(hours: 1)),
      );
    }).toList();
  }

  // EPG titles from Xtream are sometimes base64-encoded
  String _decodeTitle(String raw) {
    if (raw.isEmpty) return raw;
    try {
      if (raw.length % 4 == 0 &&
          RegExp(r'^[A-Za-z0-9+/]+=*$').hasMatch(raw)) {
        return utf8.decode(base64Decode(raw));
      }
    } catch (_) {}
    return raw;
  }
}
