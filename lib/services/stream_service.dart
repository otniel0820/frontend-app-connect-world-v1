import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stream_info.dart';
import 'xtream_service.dart';

final streamServiceProvider = Provider<StreamService>((ref) {
  return StreamService(ref.watch(xtreamServiceProvider));
});

class StreamService {
  final XtreamService _xtream;

  StreamService(this._xtream);

  /// Builds a playable StreamInfo from the encoded stream ID.
  /// No network call — URL is constructed locally from credentials.
  Future<StreamInfo> getStreamUrl(String encodedId) async {
    return _xtream.buildStreamInfo(encodedId);
  }
}
