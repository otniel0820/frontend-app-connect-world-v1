import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/networking/api_client.dart';
import '../core/constants/app_constants.dart';
import '../models/epg_item.dart';

final epgServiceProvider = Provider<EpgService>((ref) {
  return EpgService(ref.watch(apiClientProvider));
});

class EpgService {
  final ApiClient _client;

  EpgService(this._client);

  /// Fetches EPG programs for [channelId] between [from] and [to].
  /// If [from]/[to] are omitted the backend returns the full stored range.
  Future<List<EpgItem>> getEpg({
    required String channelId,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _client.get<List<dynamic>>(
      ApiConstants.epg,
      queryParameters: {
        'channelId': channelId,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    return (response.data as List)
        .map((e) => EpgItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Convenience: fetch programs for today only.
  Future<List<EpgItem>> getTodayEpg({required String channelId}) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getEpg(channelId: channelId, from: startOfDay, to: endOfDay);
  }
}
