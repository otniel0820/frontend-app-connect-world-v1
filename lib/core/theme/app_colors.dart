import 'package:flutter/material.dart';

abstract class AppColors {
  // Background — azul marino muy oscuro como el backoffice
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF151827);
  static const Color surfaceVariant = Color(0xFF1A1D2E);
  static const Color surfaceCard = Color(0xFF1E2235);

  // Brand — violeta/morado del backoffice
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color primaryOverlay = Color(0x337C3AED);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFF6B7280);

  // Border
  static const Color border = Color(0xFF2D3148);

  // Focus (TV)
  static const Color focusBorder = Color(0xFF8B5CF6);
  static const Color focusOverlay = Color(0x338B5CF6);

  // Status
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // Gradient — banner con tono oscuro azulado
  static const LinearGradient bannerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC0F1117), Color(0xFF0F1117)],
    stops: [0.3, 0.75, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xDD0F1117)],
  );

  // Gradiente de fondo del sidebar / login igual al backoffice
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F1117), Color(0xFF151827)],
  );
}
