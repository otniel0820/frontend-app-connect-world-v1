import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/search_provider.dart';
import '../../home/widgets/content_row.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search movies, series, channels...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textHint),
          ),
          onChanged: (q) => ref.read(searchQueryProvider.notifier).state = q,
        ),
        backgroundColor: AppColors.background,
      ),
      body: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (results) {
          final query = ref.watch(searchQueryProvider);
          if (query.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('Search for something', style: TextStyle(color: AppColors.textHint)),
                ],
              ),
            );
          }

          final hasResults = results.movies.isNotEmpty ||
              results.series.isNotEmpty ||
              results.channels.isNotEmpty;

          if (!hasResults) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No results for "$query"',
                    style: const TextStyle(color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              if (results.movies.isNotEmpty)
                ContentRow(
                  title: 'Movies',
                  items: results.movies
                      .map((m) => ContentItem(id: m.id, title: m.title, imageUrl: m.posterUrl))
                      .toList(),
                ),
              if (results.series.isNotEmpty)
                ContentRow(
                  title: 'Series',
                  items: results.series
                      .map((s) => ContentItem(id: s.id, title: s.title, imageUrl: s.posterUrl))
                      .toList(),
                ),
              if (results.channels.isNotEmpty)
                ContentRow(
                  title: 'Channels',
                  items: results.channels
                      .map((c) => ContentItem(id: c.id, title: c.name, imageUrl: c.logoUrl))
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}
