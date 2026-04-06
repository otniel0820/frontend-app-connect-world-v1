import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/tv_search_bar.dart';
import '../../../models/channel.dart';
import '../providers/live_tv_provider.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  String? _selectedGroup; // null = Todos
  String _query = '';

  late final FocusNode _searchFocusNode;
  late final FocusNode _firstChipFocus;
  late final FocusNode _firstChannelFocus;
  bool _channelsFocused = false;
  final _scrollController = ScrollController();
  final Map<int, FocusNode> _chipNodes = {};

  FocusNode _chipNode(int index) {
    if (index == 0) return _firstChipFocus;
    return _chipNodes.putIfAbsent(index, () => FocusNode());
  }

  @override
  void initState() {
    super.initState();
    _firstChannelFocus = FocusNode();
    _firstChipFocus = FocusNode();
    _searchFocusNode = FocusNode();

    // Register with navbar so DOWN from navbar goes to first channel
    NavbarFocus.registerContentFirst(_firstChannelFocus);
  }

  void _tryFocusFirstChannel() {
    if (!_channelsFocused) {
      _channelsFocused = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _firstChannelFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    NavbarFocus.unregisterContentFirst();
    _searchFocusNode.dispose();
    _firstChipFocus.dispose();
    _firstChannelFocus.dispose();
    _scrollController.dispose();
    for (final n in _chipNodes.values) { n.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);

    // Focus first channel card once data is available (handles both fresh load and cached data)
    ref.listen(channelsProvider, (prev, next) {
      next.whenData((_) => _tryFocusFirstChannel());
    });
    channelsAsync.whenData((_) => _tryFocusFirstChannel());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: channelsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error: $e',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () => ref.invalidate(channelsProvider),
                  child: const Text('Reintentar')),
            ],
          ),
        ),
        data: (channels) {
          // Sorted group list
          final groups = channels
              .map((c) =>
                  c.groupTitle?.isNotEmpty == true ? c.groupTitle! : 'General')
              .toSet()
              .toList()
            ..sort();

          // Apply filters
          final filtered = channels.where((c) {
            final group = c.groupTitle?.isNotEmpty == true
                ? c.groupTitle!
                : 'General';
            final inGroup =
                _selectedGroup == null || group == _selectedGroup;
            final inSearch = _query.isEmpty ||
                c.name.toLowerCase().contains(_query.toLowerCase());
            return inGroup && inSearch;
          }).toList();

          // Count per group for chip labels
          final Map<String, int> groupCounts = {};
          for (final c in channels) {
            final g = c.groupTitle?.isNotEmpty == true
                ? c.groupTitle!
                : 'General';
            groupCounts[g] = (groupCounts[g] ?? 0) + 1;
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Sticky header: search + chips + count ──────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeader(
                  height: 128,
                  child: Container(
                    color: AppColors.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: TvSearchBar(
                            navFocusNode: _searchFocusNode,
                            hintText: 'Buscar canal...',
                            onChanged: (v) => setState(() => _query = v),
                            onUp: () => NavbarFocus.requestFocus(),
                            onDown: () => _firstChipFocus.requestFocus(),
                          ),
                        ),
                        SizedBox(
                          height: 46,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: groups.length + 1,
                            itemBuilder: (context, index) {
                              final isAll = index == 0;
                              final groupName =
                                  isAll ? 'Todos' : groups[index - 1];
                              final count = isAll
                                  ? channels.length
                                  : (groupCounts[groupName] ?? 0);
                              final selected = isAll
                                  ? _selectedGroup == null
                                  : _selectedGroup == groupName;
                              final totalChips = groups.length + 1;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _ChipItem(
                                  focusNode: _chipNode(index),
                                  label: '$groupName ($count)',
                                  selected: selected,
                                  onSelected: () {
                                    setState(() {
                                      _selectedGroup =
                                          isAll ? null : groupName;
                                    });
                                    if (_scrollController.hasClients) {
                                      _scrollController.animateTo(0,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeOut);
                                    }
                                  },
                                  onUp: () =>
                                      _searchFocusNode.requestFocus(),
                                  onDown: () {
                                    if (_scrollController.hasClients) {
                                      _scrollController.jumpTo(0);
                                    }
                                  },
                                  onRight: index < totalChips - 1
                                      ? () => _chipNode(index + 1).requestFocus()
                                      : null,
                                  onLeft: index > 0
                                      ? () => _chipNode(index - 1).requestFocus()
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                          child: Text(
                            '${filtered.length} canal${filtered.length != 1 ? 'es' : ''}',
                            style: const TextStyle(
                                color: AppColors.textHint, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Vertical grid ───────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 48),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.55,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ChannelCard(
                      channel: filtered[index],
                      focusNode: index == 0 ? _firstChannelFocus : null,
                      onUpFromTopRow: () => _firstChipFocus.requestFocus(),
                      isTopRow: index < 4,
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sticky header delegate ────────────────────────────────────────────────────

class _StickyHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  const _StickyHeader({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_StickyHeader old) => true;
}

// ── Chip with proper D-pad focus ──────────────────────────────────────────────

class _ChipItem extends StatefulWidget {
  final FocusNode? focusNode;
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback? onRight;
  final VoidCallback? onLeft;

  const _ChipItem({
    this.focusNode,
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.onUp,
    required this.onDown,
    this.onRight,
    this.onLeft,
  });

  @override
  State<_ChipItem> createState() => _ChipItemState();
}

class _ChipItemState extends State<_ChipItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          widget.onSelected();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          widget.onUp();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          widget.onDown(); // scroll to top
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              FocusScope.of(context).focusInDirection(TraversalDirection.down);
            }
          });
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          widget.onRight?.call();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.onLeft?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focused
                  ? Colors.white
                  : (widget.selected ? AppColors.primary : AppColors.border),
              width: _focused ? 2 : 1,
            ),
            boxShadow: _focused
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              color: widget.selected ? Colors.white : AppColors.textSecondary,
              fontWeight:
                  widget.selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Channel card ──────────────────────────────────────────────────────────────

class _ChannelCard extends StatefulWidget {
  final Channel channel;
  final FocusNode? focusNode;
  final VoidCallback? onUpFromTopRow;
  final bool isTopRow;

  const _ChannelCard({
    required this.channel,
    this.focusNode,
    this.onUpFromTopRow,
    this.isTopRow = false,
  });

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> {
  bool _focused = false;

  void _open() => context.push(AppRoutes.player, extra: {
        'id': widget.channel.id,
        'title': widget.channel.name,
        'startPositionMs': 0,
      });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _open();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
            widget.isTopRow &&
            widget.onUpFromTopRow != null) {
          widget.onUpFromTopRow!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _open,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? AppColors.primary : AppColors.border,
              width: _focused ? 2 : 1,
            ),
            boxShadow: _focused
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: widget.channel.logoUrl?.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: widget.channel.logoUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.live_tv,
                              color: AppColors.textHint,
                              size: 28),
                        )
                      : const Icon(Icons.live_tv,
                          color: AppColors.textHint, size: 28),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                child: Text(
                  widget.channel.name,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
