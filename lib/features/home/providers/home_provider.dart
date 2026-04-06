import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/catalog.dart';
import '../../../services/catalog_service.dart';

/// Refresca el catálogo del home cada 30 minutos para mostrar
/// siempre el contenido HD/4K más reciente.
const _kCatalogRefreshInterval = Duration(minutes: 30);

final catalogProvider = FutureProvider<Catalog>((ref) async {
  final service = ref.watch(catalogServiceProvider);

  // Auto-invalidate after the refresh interval so new HD/4K content
  // added via sync is picked up without restarting the app.
  final timer = Stream<void>.periodic(_kCatalogRefreshInterval).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return service.getCatalog();
});
