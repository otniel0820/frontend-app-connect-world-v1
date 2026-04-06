import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// A search bar designed for TV/Android TV.
///
/// In "nav mode" (D-pad navigation): receives focus, shows a styled container,
/// but does NOT open the soft keyboard.
/// In "edit mode": activated only when the user explicitly presses Enter/Select.
/// Pressing Escape/Back/GoBack exits edit mode and returns focus to nav mode.
class TvSearchBar extends StatefulWidget {
  /// FocusNode used for D-pad navigation (up/down between sections).
  final FocusNode navFocusNode;

  /// Called whenever the text changes.
  final ValueChanged<String> onChanged;

  final String hintText;

  /// Called when the user presses DOWN while in nav mode (not editing).
  final VoidCallback? onDown;

  /// Called when the user presses UP while in nav mode — úsalo para
  /// volver a la navbar: `onUp: () => NavbarFocus.requestFocus()`
  final VoidCallback? onUp;

  const TvSearchBar({
    super.key,
    required this.navFocusNode,
    required this.onChanged,
    required this.hintText,
    this.onDown,
    this.onUp,
  });

  @override
  State<TvSearchBar> createState() => _TvSearchBarState();
}

class _TvSearchBarState extends State<TvSearchBar> {
  final _editFocus = FocusNode();
  final _controller = TextEditingController();
  bool _editing = false;
  bool _navFocused = false;

  @override
  void initState() {
    super.initState();
    // Intercept Back/Escape inside the TextField to exit editing
    _editFocus.onKeyEvent = (_, event) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.goBack ||
              event.logicalKey == LogicalKeyboardKey.browserBack)) {
        _stopEditing();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editFocus.requestFocus();
    });
  }

  void _stopEditing() {
    setState(() => _editing = false);
    // Return focus to nav node so D-pad continues to work
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.navFocusNode.requestFocus();
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    _stopEditing();
  }

  @override
  void dispose() {
    _editFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // EDIT MODE — real TextField with keyboard
    if (_editing) {
      return TextField(
        focusNode: _editFocus,
        controller: _controller,
        onChanged: widget.onChanged,
        onSubmitted: (value) {
          widget.onChanged(value);
          _stopEditing();
        },
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle:
              const TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: const Icon(Icons.search,
              color: AppColors.textSecondary, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close,
                color: AppColors.textSecondary, size: 18),
            onPressed: _clear,
          ),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      );
    }

    // NAV MODE — focusable display widget, no keyboard
    return Focus(
      focusNode: widget.navFocusNode,
      onFocusChange: (f) => setState(() => _navFocused = f),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _startEditing();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          widget.onUp?.call();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          widget.onDown?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _startEditing,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _navFocused ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: _navFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: _navFocused
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _controller.text.isEmpty
                      ? widget.hintText
                      : _controller.text,
                  style: TextStyle(
                    color: _controller.text.isEmpty
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_navFocused && _controller.text.isEmpty)
                const Text(
                  'Presiona OK para escribir',
                  style: TextStyle(
                      color: AppColors.textHint, fontSize: 11),
                ),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: _clear,
                  child: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
