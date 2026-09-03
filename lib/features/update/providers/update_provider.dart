import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_release.dart';
import '../../../services/update_service.dart';

final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  return ref.watch(updateServiceProvider).checkForUpdate();
});
