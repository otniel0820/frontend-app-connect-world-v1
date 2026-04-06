import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/networking/api_client.dart';
import '../core/constants/app_constants.dart';
import '../models/stream_info.dart';

final streamServiceProvider = Provider<StreamService>((ref) {
  return StreamService(ref.watch(apiClientProvider));
});

class StreamService {
  final ApiClient _client;

  StreamService(this._client);

  Future<StreamInfo> getStreamUrl(String id) async {
    final response = await _client.get<Map<String, dynamic>>(ApiConstants.stream(id));
    return StreamInfo.fromJson(response.data!);
  }
}
