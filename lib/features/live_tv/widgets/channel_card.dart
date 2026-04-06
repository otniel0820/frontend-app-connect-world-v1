import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/channel.dart';

class ChannelCard extends StatefulWidget {
  final Channel channel;
  final VoidCallback onTap;
  const ChannelCard({super.key, required this.channel, required this.onTap});

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.channel.logoUrl != null)
                CachedNetworkImage(
                  imageUrl: widget.channel.logoUrl!,
                  height: 40,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.tv, color: AppColors.textSecondary, size: 32),
                )
              else
                const Icon(Icons.tv, color: AppColors.textSecondary, size: 32),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.channel.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
