import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import 'content_row.dart';

class ContentCard extends StatefulWidget {
  final ContentItem item;
  final FocusNode? focusNode;
  const ContentCard({super.key, required this.item, this.focusNode});

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  bool _focused = false;

  void _openDetail(BuildContext context) {
    context.push(AppRoutes.detail, extra: {
      'id': widget.item.id,
      'title': widget.item.title,
      'posterUrl': widget.item.imageUrl,
      'backdropUrl': widget.item.backdropUrl,
      'overview': widget.item.overview,
      'genre': widget.item.genre,
      'year': widget.item.year,
      'rating': widget.item.rating,
      'durationMinutes': widget.item.durationMinutes,
      'isSeries': widget.item.isSeries,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _openDetail(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? AppColors.focusBorder : Colors.transparent,
              width: 2,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.item.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: widget.item.imageUrl!,
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
                    decoration: const BoxDecoration(gradient: AppColors.cardGradient),
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Text(
                      widget.item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
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
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.movie_outlined, color: AppColors.textHint, size: 36),
      );
}
