import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/channel.dart';

class ChannelGroupScreen extends StatefulWidget {
  final String title;
  final List<Channel> channels;
  const ChannelGroupScreen(
      {super.key, required this.title, required this.channels});

  @override
  State<ChannelGroupScreen> createState() => _ChannelGroupScreenState();
}

class _ChannelGroupScreenState extends State<ChannelGroupScreen> {
  String _query = '';

  List<Channel> get _filtered => _query.isEmpty
      ? widget.channels
      : widget.channels
          .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar canal...',
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
      body: filtered.isEmpty
          ? Center(
              child: Text('Sin resultados para "$_query"',
                  style: const TextStyle(color: AppColors.textSecondary)))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _ChannelCard(channel: filtered[i]),
            ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final Channel channel;
  const _ChannelCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.player, extra: {
        'id': channel.id,
        'title': channel.name,
        'startPositionMs': 0,
      }),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: channel.logoUrl?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: channel.logoUrl!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.live_tv,
                            color: AppColors.textHint,
                            size: 26),
                      )
                    : const Icon(Icons.live_tv,
                        color: AppColors.textHint, size: 26),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                channel.name,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
