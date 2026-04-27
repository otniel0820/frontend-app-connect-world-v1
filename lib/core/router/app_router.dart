import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/live_tv/screens/live_tv_screen.dart';
import '../../features/movies/screens/movies_screen.dart';
import '../../features/series/screens/series_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/player/screens/player_screen.dart';
import '../../features/detail/screens/content_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/auth/screens/subscription_expired_screen.dart';
import '../storage/local_storage.dart';

/// Exposes the navbar's first tab FocusNode so any content widget
/// can call [NavbarFocus.requestFocus()] to return to the navbar on UP.
class NavbarFocus {
  static FocusNode? _node;
  /// Optional callback: content screens register a "first item" focus node
  /// so the navbar can navigate DOWN directly into content.
  static FocusNode? _contentFirstNode;

  /// Called internally by the navbar widget on init/dispose.
  static void _register(FocusNode node) => _node = node;
  static void _unregister() => _node = null;

  /// Called by each screen to tell the navbar where DOWN should land.
  static void registerContentFirst(FocusNode node) => _contentFirstNode = node;
  static void unregisterContentFirst() => _contentFirstNode = null;

  /// Content cards call this when the user presses UP.
  static void requestFocus() => _node?.requestFocus();

  /// Navbar calls this when the user presses DOWN.
  static void focusContent() {
    if (_contentFirstNode != null) {
      _contentFirstNode!.requestFocus();
    } else {
      // Fallback: use Flutter's default traversal
      _node?.focusInDirection(TraversalDirection.down);
    }
  }
}

abstract class AppRoutes {
  static const String login = '/login';
  static const String subscriptionExpired = '/subscription-expired';
  static const String home = '/';
  static const String liveTV = '/live-tv';
  static const String movies = '/movies';
  static const String series = '/series';
  static const String search = '/search';
  static const String player = '/player';
  static const String detail = '/detail';
  static const String profile = '/profile';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authStateProvider);
  final storage = ref.read(localStorageProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoginRoute = location == AppRoutes.login;
      final isExpiredRoute = location == AppRoutes.subscriptionExpired;

      // Already on expired screen — let through
      if (isExpiredRoute) return null;

      // Check if subscription is expired (locally stored expiresAt)
      if (isAuthenticated && storage.isSubscriptionExpired) {
        return AppRoutes.subscriptionExpired;
      }

      // Not authenticated → login
      if (!isAuthenticated && !isLoginRoute) return AppRoutes.login;

      // Authenticated on login → home
      if (isAuthenticated && isLoginRoute) return AppRoutes.home;


      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptionExpired,
        builder: (context, state) => const SubscriptionExpiredScreen(),
      ),
      GoRoute(
        path: AppRoutes.detail,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ContentDetailScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.player,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PlayerScreen(
            streamId: extra['id'] as String,
            title: extra['title'] as String,
            startPositionMs: (extra['startPositionMs'] as int?) ?? 0,
            seriesId: extra['seriesId'] as String?,
            episodes: extra['episodes'] as List<Map<String, dynamic>>?,
            episodeIndex: (extra['episodeIndex'] as int?) ?? 0,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.liveTV,
            builder: (context, state) => const LiveTvScreen(),
          ),
          GoRoute(
            path: AppRoutes.movies,
            builder: (context, state) => const MoviesScreen(),
          ),
          GoRoute(
            path: AppRoutes.series,
            builder: (context, state) => const SeriesScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

// ── Nav tabs (no profile — it's an icon button) ───────────────────────────
const _navTabs = [
  (route: AppRoutes.home, label: 'Inicio'),
  (route: AppRoutes.movies, label: 'Películas'),
  (route: AppRoutes.series, label: 'Series'),
  (route: AppRoutes.liveTV, label: 'En vivo'),
];

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final loc = GoRouterState.of(context).matchedLocation;
        if (loc != AppRoutes.home) {
          context.go(AppRoutes.home);
        } else {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _TransparentTopNav(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

void _showExitDialog(BuildContext context) {
  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.exit_to_app_rounded,
                color: AppColors.primary, size: 40),
            const SizedBox(height: 16),
            const Text(
              '¿Salir de la aplicación?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seguro que quieres salir de Connect World?',
              style: TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('No',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Sí, salir',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _TransparentTopNav extends StatefulWidget {
  @override
  State<_TransparentTopNav> createState() => _TransparentTopNavState();
}

class _TransparentTopNavState extends State<_TransparentTopNav> {
  // 0-3: nav tabs (Inicio, Películas, Series, En vivo), 4: search, 5: profile
  late final List<FocusNode> _fns;

  @override
  void initState() {
    super.initState();
    _fns = List.generate(6, (i) => FocusNode(debugLabel: 'nav_$i'));
    NavbarFocus._register(_fns[0]);
    // Solicitar foco en el primer tab después del primer frame,
    // garantizando que gane sobre cualquier autofocus del contenido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fns[0].requestFocus();
    });
  }

  @override
  void dispose() {
    NavbarFocus._unregister();
    for (final n in _fns) { n.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      color: const Color(0xFF0D0D0D),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // ── Logo ──────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    height: 52,
                    width: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 20),

                // ── Nav items ─────────────────────────────────────────
                // Tabs: 0=Inicio, 1=Películas, 2=Series, 3=En vivo
                // Chain: tab0 ↔ tab1 ↔ tab2 ↔ tab3 ↔ search(4) ↔ profile(5)
                ...List.generate(_navTabs.length, (i) {
                  final tab = _navTabs[i];
                  final isActive = location == tab.route;
                  return _NavItem(
                    focusNode: _fns[i],
                    prevFocus: i > 0 ? _fns[i - 1] : null,
                    nextFocus: _fns[i + 1], // tab3 → search(_fns[4])
                    label: tab.label,
                    isActive: isActive,
                    autofocus: false,
                    onTap: () => context.go(tab.route),
                  );
                }),

                const Spacer(),

                // ── Search icon ───────────────────────────────────────
                _IconBtn(
                  focusNode: _fns[4],
                  prevFocus: _fns[3],
                  nextFocus: _fns[5],
                  icon: Icons.search,
                  onTap: () => context.push(AppRoutes.search),
                ),
                const SizedBox(width: 4),

                // ── Profile icon ──────────────────────────────────────
                _IconBtn(
                  focusNode: _fns[5],
                  prevFocus: _fns[4],
                  nextFocus: null,
                  icon: location == AppRoutes.profile
                      ? Icons.person
                      : Icons.person_outline,
                  color: location == AppRoutes.profile
                      ? AppColors.primaryLight
                      : Colors.white,
                  onTap: () => context.go(AppRoutes.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final FocusNode focusNode;
  final FocusNode? prevFocus;
  final FocusNode? nextFocus;
  final String label;
  final bool isActive;
  final bool autofocus;
  final VoidCallback onTap;
  const _NavItem({
    required this.focusNode,
    this.prevFocus,
    this.nextFocus,
    required this.label,
    required this.isActive,
    this.autofocus = false,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.prevFocus?.requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          widget.nextFocus?.requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          NavbarFocus.focusContent();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _focused ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive || _focused ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: widget.isActive ? 20 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final FocusNode focusNode;
  final FocusNode? prevFocus;
  final FocusNode? nextFocus;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _IconBtn({
    required this.focusNode,
    this.prevFocus,
    this.nextFocus,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
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
          widget.onTap();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.prevFocus?.requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          widget.nextFocus?.requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          NavbarFocus.focusContent();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _focused ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: widget.color ?? Colors.white, size: 24),
        ),
      ),
    );
  }
}
