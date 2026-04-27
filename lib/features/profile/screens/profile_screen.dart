import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/local_storage.dart';
import '../../../features/home/widgets/content_row.dart';
import '../../../services/xtream_service.dart';
import '../../../models/movie.dart';
import '../../../models/series.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = 'v${info.version}');
    });
  }

  String _formatExpiry(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return 'Sin fecha';
    }
  }

  void _showContentSheet(
    BuildContext context,
    String title,
    List<ContentItem> items,
  ) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tienes $title aún'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _ContentSheet(title: title, items: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.read(localStorageProvider);
    final username = storage.getUsername() ?? 'Usuario';
    final hideAdult = storage.hideAdultContent;
    final favoriteIds = storage.getFavoriteIds();
    final continueWatchingMap = storage.getContinueWatching();
    final expiresAtStr = storage.getExpiresAt();
    final isExpired = expiresAtStr != null &&
        DateTime.tryParse(expiresAtStr)?.toLocal().isBefore(DateTime.now()) ==
            true;

    // Build ContentItem lists from raw catalog for favorites/CW display
    final moviesAsync = ref.watch(rawMoviesProvider);
    final seriesAsync = ref.watch(rawSeriesProvider);

    List<ContentItem> favoriteItems = [];
    List<ContentItem> continueItems = [];

    final movies = moviesAsync.value ?? <Movie>[];
    final seriesList = seriesAsync.value ?? <Series>[];

    final allItems = [
      ...movies.map((m) => ContentItem(
            id: m.id,
            title: m.title,
            imageUrl: m.posterUrl,
            genre: m.genre,
            rating: m.rating,
          )),
      ...seriesList.map((s) => ContentItem(
            id: s.id,
            title: s.title,
            imageUrl: s.posterUrl,
            backdropUrl: s.backdropUrl,
            overview: s.overview,
            genre: s.genre,
            year: s.releaseYear,
            rating: s.rating,
            isSeries: true,
          )),
    ];

    favoriteItems = allItems.where((i) => favoriteIds.contains(i.id)).toList();
    continueItems =
        allItems.where((i) => continueWatchingMap.containsKey(i.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.arrowUp) {
                NavbarFocus.requestFocus();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            skipTraversal: true,
            canRequestFocus: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      children: [
                        // ── Avatar ──────────────────────────────────────
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Username ─────────────────────────────────────
                        Text(
                          username,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ── Server URL ───────────────────────────────────
                        Text(
                          storage.getXtreamUrl() ?? '',
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 28),

                        // ── Expiry card ──────────────────────────────────
                        _InfoCard(
                          icon: Icons.access_time_outlined,
                          label: 'Vencimiento de cuenta',
                          value: _formatExpiry(expiresAtStr),
                          valueColor:
                              isExpired ? AppColors.error : AppColors.success,
                          trailing: isExpired
                              ? const _Badge(
                                  label: 'EXPIRADO', color: AppColors.error)
                              : const _Badge(
                                  label: 'ACTIVO', color: AppColors.success),
                        ),
                        const SizedBox(height: 12),

                        // ── Control parental (local) ─────────────────────
                        _ParentalControlCard(
                          hideAdultContent: hideAdult,
                          storage: storage,
                        ),
                        const SizedBox(height: 12),

                        // ── Stat cards ───────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.favorite_outline,
                                label: 'Favoritos',
                                value: favoriteIds.length.toString(),
                                onTap: () => _showContentSheet(
                                    context, 'Favoritos', favoriteItems),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.play_circle_outline,
                                label: 'Continuar\nviendo',
                                value: continueWatchingMap.length.toString(),
                                onTap: () => _showContentSheet(
                                    context, 'Continuar viendo', continueItems),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Logout ───────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .logout();
                              if (context.mounted) {
                                context.go(AppRoutes.login);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Version overlay
          if (_appVersion.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 16,
              child: Text(
                _appVersion,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom sheet ─────────────────────────────────────────────────────────────

class _ContentSheet extends StatelessWidget {
  final String title;
  final List<ContentItem> items;
  const _ContentSheet({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${items.length}',
                      style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.62,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _SheetCard(item: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  final ContentItem item;
  const _SheetCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push(AppRoutes.detail, extra: {
          'id': item.id,
          'title': item.title,
          'posterUrl': item.imageUrl,
          'backdropUrl': item.backdropUrl,
          'overview': item.overview,
          'genre': item.genre,
          'year': item.year,
          'rating': item.rating,
        });
      },
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
                decoration:
                    const BoxDecoration(gradient: AppColors.cardGradient),
                padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                child: Text(
                  item.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
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

// ── Control parental local ────────────────────────────────────────────────────

class _ParentalControlCard extends StatefulWidget {
  final bool hideAdultContent;
  final LocalStorage storage;
  const _ParentalControlCard(
      {required this.hideAdultContent, required this.storage});

  @override
  State<_ParentalControlCard> createState() => _ParentalControlCardState();
}

class _ParentalControlCardState extends State<_ParentalControlCard> {
  late bool _hideAdult;

  @override
  void initState() {
    super.initState();
    _hideAdult = widget.hideAdultContent;
  }

  Future<void> _activate(String pin) async {
    await widget.storage.saveParentalPin(pin);
    await widget.storage.saveHideAdultContent(true);
    if (mounted) setState(() => _hideAdult = true);
  }

  Future<void> _deactivate(String pin) async {
    if (!widget.storage.verifyParentalPin(pin)) {
      throw Exception('PIN incorrecto');
    }
    await widget.storage.clearParentalPin();
    await widget.storage.saveHideAdultContent(false);
    if (mounted) setState(() => _hideAdult = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline,
              color: _hideAdult ? AppColors.primary : AppColors.textSecondary,
              size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Control parental',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _hideAdult
                      ? 'Activo — contenido adulto bloqueado'
                      : 'Desactivado',
                  style: TextStyle(
                    color: _hideAdult ? AppColors.success : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _hideAdult
                ? _showDisableDialog(context)
                : _showSetPinDialog(context),
            style: TextButton.styleFrom(
              foregroundColor:
                  _hideAdult ? AppColors.error : AppColors.primary,
            ),
            child: Text(_hideAdult ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
  }

  void _showSetPinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _SetPinDialog(
        onConfirm: (pin) async {
          await _activate(pin);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Control parental activado'),
                  backgroundColor: AppColors.success),
            );
          }
        },
      ),
    );
  }

  void _showDisableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _VerifyPinDialog(
        onConfirm: (pin) async {
          await _deactivate(pin);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Control parental desactivado'),
                  backgroundColor: AppColors.surface),
            );
          }
        },
      ),
    );
  }
}

// ── PIN dialogs ─────────────────────────────────────────────────────────────

class _SetPinDialog extends StatefulWidget {
  final Future<void> Function(String pin) onConfirm;
  const _SetPinDialog({required this.onConfirm});
  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'El PIN debe tener 4 dígitos');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'Los PINs no coinciden');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onConfirm(pin);
    } catch (e) {
      if (mounted) setState(() {_loading = false; _error = e.toString();});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Activar control parental',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Crea un PIN de 4 dígitos para bloquear el contenido adulto.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          _PinField(controller: _pinCtrl, label: 'PIN'),
          const SizedBox(height: 12),
          _PinField(controller: _confirmCtrl, label: 'Confirmar PIN'),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Activar',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _VerifyPinDialog extends StatefulWidget {
  final Future<void> Function(String pin) onConfirm;
  const _VerifyPinDialog({required this.onConfirm});
  @override
  State<_VerifyPinDialog> createState() => _VerifyPinDialogState();
}

class _VerifyPinDialogState extends State<_VerifyPinDialog> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'Ingresa los 4 dígitos del PIN');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onConfirm(pin);
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'PIN incorrecto';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Desactivar control parental',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ingresa tu PIN para desactivar el control parental.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          _PinField(controller: _pinCtrl, label: 'PIN'),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _PinField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        letterSpacing: 12,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: valueColor ?? AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onTap});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          NavbarFocus.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.focusBorder : AppColors.border,
              width: _focused ? 2 : 1,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1)
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(widget.icon,
                  color: _focused ? AppColors.primaryLight : AppColors.primary,
                  size: 28),
              const SizedBox(height: 8),
              Text(widget.value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ver',
                      style: TextStyle(
                          color: _focused
                              ? AppColors.primaryLight
                              : AppColors.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_ios,
                      size: 10, color: AppColors.primaryLight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5),
      ),
    );
  }
}
