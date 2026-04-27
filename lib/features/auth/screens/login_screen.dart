import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

// ─── Índices D-pad ─────────────────────────────────────────────────────────
const _kUrl = 0;
const _kUsername = 1;
const _kPassword = 2;
const _kEye = 3;
const _kButton = 4;
const _kDemo = 5;
const _kFieldCount = 6;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _urlCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Foco D-pad (navegación entre elementos)
  final List<FocusNode> _navFocus =
      List.generate(_kFieldCount, (_) => FocusNode(skipTraversal: true));

  // Foco real de cada TextField (abre teclado)
  final _urlTextFocus = FocusNode();
  final _usernameTextFocus = FocusNode();
  final _passwordTextFocus = FocusNode();

  int _focusedIndex = 0;
  int? _editingIndex;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navFocus[_kUrl].requestFocus();
    });
    for (int i = 0; i < _navFocus.length; i++) {
      final idx = i;
      _navFocus[idx].onKeyEvent = (node, event) => _handleDpad(event, idx);
    }
  }

  KeyEventResult _handleDpad(KeyEvent event, int idx) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_editingIndex == idx) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (idx == _kButton) {
        _login();
      } else if (idx == _kDemo) {
        _loginDemo();
      } else if (idx == _kEye) {
        setState(() => _obscurePassword = !_obscurePassword);
      } else {
        _enterEditMode(idx);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(idx + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(idx - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveFocus(int idx) {
    final next = idx.clamp(0, _navFocus.length - 1);
    setState(() => _focusedIndex = next);
    _navFocus[next].requestFocus();
  }

  void _enterEditMode(int idx) {
    setState(() => _editingIndex = idx);
    _textFocusForIndex(idx)?.requestFocus();
  }

  void _exitEditMode() {
    if (_editingIndex == null) return;
    final idx = _editingIndex!;
    _textFocusForIndex(idx)?.unfocus();
    setState(() => _editingIndex = null);
    _navFocus[idx].requestFocus();
  }

  FocusNode? _textFocusForIndex(int idx) {
    switch (idx) {
      case _kUrl:
        return _urlTextFocus;
      case _kUsername:
        return _usernameTextFocus;
      case _kPassword:
        return _passwordTextFocus;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    for (final f in _navFocus) {
      f.dispose();
    }
    _urlTextFocus.dispose();
    _usernameTextFocus.dispose();
    _passwordTextFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
          _urlCtrl.text.trim(),
          _usernameCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasValue && authState.value != null) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _loginDemo() async {
    await ref.read(authNotifierProvider.notifier).loginDemo();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background — fallback to solid color if image not present
          Image.asset(
            'assets/images/login_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF0D0D0D)),
          ),
          Container(color: Colors.black.withValues(alpha: 0.60)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: size.width > 800 ? 480 : 420),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Logo + título ──────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset('assets/images/logo.jpg',
                                    height: 52, width: 52),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connect World',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Ingresa las credenciales de tu servicio',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── URL del servidor ───────────────────────────
                          _TvField(
                            controller: _urlCtrl,
                            navFocus: _navFocus[_kUrl],
                            textFocus: _urlTextFocus,
                            label: 'URL del servidor',
                            hint: 'http://tu-proveedor.com:8080',
                            icon: Icons.dns_outlined,
                            isFocused: _focusedIndex == _kUrl,
                            isEditing: _editingIndex == _kUrl,
                            keyboardType: TextInputType.url,
                            onSubmitted: (_) => _exitEditMode(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Requerido';
                              }
                              final trimmed = v.trim();
                              if (!trimmed.startsWith('http://') &&
                                  !trimmed.startsWith('https://')) {
                                return 'Debe empezar con http:// o https://';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // ── Usuario ────────────────────────────────────
                          _TvField(
                            controller: _usernameCtrl,
                            navFocus: _navFocus[_kUsername],
                            textFocus: _usernameTextFocus,
                            label: 'Usuario',
                            icon: Icons.person_outline,
                            isFocused: _focusedIndex == _kUsername,
                            isEditing: _editingIndex == _kUsername,
                            onSubmitted: (_) => _exitEditMode(),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                          ),
                          const SizedBox(height: 10),

                          // ── Contraseña ─────────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _TvField(
                                  controller: _passwordCtrl,
                                  navFocus: _navFocus[_kPassword],
                                  textFocus: _passwordTextFocus,
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  isFocused: _focusedIndex == _kPassword,
                                  isEditing: _editingIndex == _kPassword,
                                  onSubmitted: (_) => _exitEditMode(),
                                  validator: (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Requerido'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Ojo para mostrar/ocultar contraseña
                              Focus(
                                focusNode: _navFocus[_kEye],
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: _focusedIndex == _kEye
                                          ? AppColors.primary
                                              .withValues(alpha: 0.3)
                                          : Colors.white
                                              .withValues(alpha: 0.07),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _focusedIndex == _kEye
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: _focusedIndex == _kEye
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ── Error ──────────────────────────────────────
                          if (authState.hasError) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.error
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _friendlyError(
                                    authState.error.toString()),
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // ── Botón ingresar ─────────────────────────────
                          Focus(
                            focusNode: _navFocus[_kButton],
                            child: Builder(builder: (context) {
                              final focused = _focusedIndex == _kButton;
                              return AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 150),
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: focused
                                      ? Border.all(
                                          color: Colors.white, width: 2)
                                      : null,
                                ),
                                child: ElevatedButton(
                                  focusNode:
                                      FocusNode(skipTraversal: true),
                                  onPressed: isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    elevation: focused ? 8 : 4,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : const Text('Ingresar',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight.bold)),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 10),

                          // ── Botón demo ─────────────────────────────────
                          Focus(
                            focusNode: _navFocus[_kDemo],
                            child: Builder(builder: (context) {
                              final focused = _focusedIndex == _kDemo;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: focused
                                      ? Border.all(color: Colors.white70, width: 1.5)
                                      : null,
                                ),
                                child: TextButton(
                                  focusNode: FocusNode(skipTraversal: true),
                                  onPressed: isLoading ? null : _loginDemo,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Ver demo',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('incorrectos') || raw.contains('credentials')) {
      return 'Usuario o contraseña incorrectos.';
    }
    if (raw.contains('conectar') ||
        raw.contains('connect') ||
        raw.contains('timeout') ||
        raw.contains('URL')) {
      return 'No se pudo conectar. Verifica la URL del servidor.';
    }
    if (raw.contains('inesperada') || raw.contains('inválidas')) {
      return 'El servidor no respondió correctamente. Verifica la URL.';
    }
    return raw.replaceFirst('Exception: ', '');
  }
}

// ─── Widget campo TV-friendly ───────────────────────────────────────────────

class _TvField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode navFocus;
  final FocusNode textFocus;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscureText;
  final bool isFocused;
  final bool isEditing;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const _TvField({
    required this.controller,
    required this.navFocus,
    required this.textFocus,
    required this.label,
    required this.icon,
    required this.isFocused,
    required this.isEditing,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isEditing
        ? AppColors.primary
        : isFocused
            ? Colors.white70
            : Colors.transparent;

    return Focus(
      focusNode: navFocus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: TextFormField(
          controller: controller,
          focusNode: textFocus,
          readOnly: !isEditing,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          style:
              const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          onFieldSubmitted: onSubmitted,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppColors.textHint, fontSize: 12),
            prefixIcon:
                Icon(icon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: isFocused
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.07),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            labelStyle: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
