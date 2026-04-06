import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../home/widgets/content_row.dart';

class GenreGridScreen extends StatefulWidget {
  final String title;
  final List<ContentItem> items;

  const GenreGridScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<GenreGridScreen> createState() => _GenreGridScreenState();
}

class _GenreGridScreenState extends State<GenreGridScreen> {
  String _query = '';
  late List<ContentItem> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
              .where((i) => i.title.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: _onSearch,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar en ${widget.title}...',
                hintStyle:
                    const TextStyle(color: AppColors.textHint, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _filtered.isEmpty
          ? Center(
              child: Text(
                'Sin resultados para "$_query"',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.67,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, index) =>
                  _GridCard(item: _filtered[index]),
            ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final ContentItem item;
  const _GridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.detail, extra: {
        'id': item.id,
        'title': item.title,
        'posterUrl': item.imageUrl,
        'backdropUrl': item.backdropUrl,
        'overview': item.overview,
        'genre': item.genre,
        'year': item.year,
        'rating': item.rating,
        'durationMinutes': item.durationMinutes,
      }),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: item.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xEE0F1117)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.movie_outlined,
            color: AppColors.textHint, size: 32),
      );
}
