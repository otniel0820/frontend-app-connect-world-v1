import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import 'content_card.dart';

class ContentItem {
  final String id;
  final String title;
  final String? imageUrl;
  final String? backdropUrl;
  final String? overview;
  final String? genre;
  final dynamic year;
  final dynamic rating;
  final int? durationMinutes;
  final bool isSeries;

  const ContentItem({
    required this.id,
    required this.title,
    this.imageUrl,
    this.backdropUrl,
    this.overview,
    this.genre,
    this.year,
    this.rating,
    this.durationMinutes,
    this.isSeries = false,
  });
}

class ContentRow extends StatelessWidget {
  final String title;
  final List<ContentItem> items;
  final VoidCallback? onSeeAll;
  /// Called when UP is pressed from any card in this row.
  /// Defaults to NavbarFocus.requestFocus() if null.
  final VoidCallback? onUp;
  /// Called when DOWN is pressed from any card in this row.
  final VoidCallback? onDown;
  /// When provided, this FocusNode is assigned to the first card in the row
  /// so callers can directly focus it via [FocusNode.requestFocus()].
  final FocusNode? firstCardFocusNode;

  const ContentRow({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
    this.onUp,
    this.onDown,
    this.firstCardFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowUp) {
            (onUp ?? NavbarFocus.requestFocus)();
            return KeyEventResult.handled;
          }
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowDown &&
              onDown != null) {
            onDown!();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (onSeeAll != null)
                    // High traversal order so D-pad enters cards first
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(100),
                      child: TextButton(
                        onPressed: onSeeAll,
                        child: const Row(
                          children: [
                            Text('Ver todo',
                                style: TextStyle(
                                    color: AppColors.primary, fontSize: 13)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios,
                                size: 12, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Low traversal order so cards are focused before "Ver todo"
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => ContentCard(
                    item: items[index],
                    focusNode: index == 0 ? firstCardFocusNode : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
