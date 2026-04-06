import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/catalog.dart';
import '../../home/providers/home_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<AsyncValue<Catalog>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final catalogAsync = ref.watch(catalogProvider);

  if (query.isEmpty) return const AsyncData(Catalog());

  return catalogAsync.whenData((catalog) => Catalog(
        movies: catalog.movies.where((m) => m.title.toLowerCase().contains(query)).toList(),
        series: catalog.series.where((s) => s.title.toLowerCase().contains(query)).toList(),
        channels: catalog.channels.where((c) => c.name.toLowerCase().contains(query)).toList(),
      ));
});
