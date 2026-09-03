import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/app_release.dart';
import '../../../services/update_service.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.isForced,
      builder: (_) => UpdateDialog(info: info),
    );
  }

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  final _cancelToken = CancelToken();
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  @override
  void dispose() {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel();
    }
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });

    try {
      await ref.read(updateServiceProvider).downloadAndInstall(
            widget.info.release,
            cancelToken: _cancelToken,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      if (mounted) setState(() => _downloading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error =
              'No se pudo descargar. Abre la página de descarga e instala a mano.';
        });
      }
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.info.release.htmlUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.info.release;

    return PopScope(
      canPop: !widget.info.isForced && !_downloading,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          widget.info.isForced
              ? 'Actualización requerida'
              : 'Nueva versión disponible',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'v${release.version}',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tienes la v${widget.info.currentVersion}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (release.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Text(
                      release.notes,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
              if (_downloading) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 6),
                Text(
                  'Descargando ${(_progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: _downloading
            ? null
            : [
                if (!widget.info.isForced)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Después',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                if (_error != null)
                  TextButton(
                    onPressed: _openInBrowser,
                    child: const Text('Abrir en navegador'),
                  ),
                FilledButton(
                  autofocus: true,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: _start,
                  child: const Text('Actualizar ahora'),
                ),
              ],
      ),
    );
  }
}
