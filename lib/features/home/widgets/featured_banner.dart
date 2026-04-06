import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/movie.dart';

class FeaturedBanner extends StatelessWidget {
  final Movie movie;
  const FeaturedBanner({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop
          if (movie.backdropUrl != null)
            CachedNetworkImage(
              imageUrl: movie.backdropUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: AppColors.surface),
            )
          else
            Container(color: AppColors.surface),

          // Gradient overlay
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.bannerGradient),
          ),

          // Left side gradient for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.background.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 56,
            left: 40,
            right: MediaQuery.of(context).size.width * 0.45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre badge
                if (movie.genre != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      movie.genre!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Title
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Meta
                if (movie.releaseYear != null || movie.rating != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (movie.releaseYear != null)
                        Text(
                          movie.releaseYear.toString(),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      if (movie.releaseYear != null && movie.rating != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('·',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      if (movie.rating != null && movie.rating != 0)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFFBBF24), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              movie.rating is double
                                  ? (movie.rating as double).toStringAsFixed(1)
                                  : movie.rating.toString(),
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],

                // Overview
                if (movie.overview != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    movie.overview!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 24),

                // Buttons — wrapped in Focus to handle UP → navbar on TV
                Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      NavbarFocus.requestFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.player,
                        extra: {
                          'id': movie.id,
                          'title': movie.title,
                          'startPositionMs': 0,
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 22),
                      label: const Text('Reproducir',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.detail,
                        extra: {
                          'id': movie.id,
                          'title': movie.title,
                          'posterUrl': movie.posterUrl,
                          'backdropUrl': movie.backdropUrl,
                          'overview': movie.overview,
                          'genre': movie.genre,
                          'year': movie.releaseYear,
                          'rating': movie.rating,
                        },
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.info_outline, size: 20),
                      label: const Text('Más info'),
                    ),
                  ],
                  ),  // Row
                ),  // Focus
              ],
            ),
          ),
        ],
      ),
    );
  }
}
