import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF1E3A8A); // أزرق داكن احترافي
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);

  // Secondary & Accents
  static const Color accent = Color(0xFFF59E0B); // برتقالي ذهبي
  static const Color accentLight = Color(0xFFFDE68A);

  // Status Colors
  static const Color success = Color(0xFF10B981); // أخضر للإنجاز والقبول
  static const Color warning = Color(0xFFF59E0B); // أصفر للمراجعة والانتظار
  static const Color danger = Color(0xFFEF4444);  // أحمر للإلغاء والرفض
  static const Color info = Color(0xFF0EA5E9);    // أزرق سماوي للمعلومات

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF312E81)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
