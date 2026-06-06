import 'package:flutter/material.dart';

/// ألوان مستوحاة من شعار العيادة (أخضر + سن).
abstract final class AppColors {
  static const primary = Color(0xFF1E5631);
  static const primaryDark = Color(0xFF163D24);
  static const primaryLight = Color(0xFF3D9B5F);
  static const accent = Color(0xFF52B788);
  static const surface = Color(0xFFF4F9F6);
  static const card = Colors.white;

  static const success = Color(0xFF276749);
  static const warning = Color(0xFFC05621);
  static const danger = Color(0xFFC53030);
  static const info = Color(0xFF2B6CB0);
  static const purple = Color(0xFF6B46C1);

  static const headerGradient = [
    primaryDark,
    primary,
    primaryLight,
  ];

  static Color brandColor(String brand) => switch (brand) {
        'Straumann' => const Color(0xFF2B6CB0),
        'BioHorizons' => const Color(0xFF276749),
        'Ora' => const Color(0xFFC05621),
        'ملحقات' => const Color(0xFF6B46C1),
        'أدوات' => const Color(0xFF2C7A7B),
        _ => const Color(0xFF718096),
      };

  static const brandGradients = {
    'Straumann': [Color(0xFF2B6CB0), Color(0xFF4299E1)],
    'BioHorizons': [Color(0xFF276749), Color(0xFF48BB78)],
    'Ora': [Color(0xFFC05621), Color(0xFFED8936)],
  };
}
