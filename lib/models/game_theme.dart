import 'package:flutter/material.dart';

/// Six-color palette per theme: background, surface, primary, secondary,
/// accent, onPrimary (text/icons drawn on primary).
class GameTheme {
  final String id;
  final String name;
  final String tagline;
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color onPrimary;
  final List<Color> playerColors; // P0..P3 piece colors

  const GameTheme({
    required this.id,
    required this.name,
    required this.tagline,
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.onPrimary,
    required this.playerColors,
  });

  ThemeData get material => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: primary,
          onPrimary: onPrimary,
          secondary: secondary,
          onSecondary: onPrimary,
          tertiary: accent,
          error: const Color(0xFFD64545),
          onError: Colors.white,
          surface: surface,
          onSurface: _onSurface,
          surfaceContainerHighest: surface,
        ),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: _onSurface,
          displayColor: _onSurface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          foregroundColor: _onSurface,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
        ),
      );

  Color get _onSurface =>
      background.computeLuminance() > 0.4 ? const Color(0xFF1A1A1A) : Colors.white;
}

const _classicPieces = [
  Color(0xFFE63946), // red
  Color(0xFF2A9D48), // green
  Color(0xFFF4B400), // gold
  Color(0xFF2D7DD2), // blue
];

/// 8 royal themes, each with a unique 6-color palette.
const List<GameTheme> gameThemes = [
  GameTheme(
    id: 'maharaja',
    name: 'Maharaja Court',
    tagline: 'The signature royal durbar',
    background: Color(0xFF1B0B1E), // deep purple-black
    surface: Color(0xFF2A0F22),
    primary: Color(0xFF8E0E2A), // royal red
    secondary: Color(0xFFD4AF37), // gold
    accent: Color(0xFFB08D3E), // brass
    onPrimary: Color(0xFFFFF8E7), // ivory
    playerColors: _classicPieces,
  ),
  GameTheme(
    id: 'midnight',
    name: 'Midnight Durbar',
    tagline: 'Neon nights of the court',
    background: Color(0xFF050914),
    surface: Color(0xFF0C1424),
    primary: Color(0xFF1E3A8A),
    secondary: Color(0xFF60A5FA),
    accent: Color(0xFFA78BFA),
    onPrimary: Color(0xFFEAF2FF),
    playerColors: [
      Color(0xFF60A5FA),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
      Color(0xFFF472B6),
    ],
  ),
  GameTheme(
    id: 'ocean',
    name: 'Ocean Pearl',
    tagline: 'Monsoon tides and pearls',
    background: Color(0xFF06222B),
    surface: Color(0xFF0A3240),
    primary: Color(0xFF0E7C8C),
    secondary: Color(0xFF7FE3D0),
    accent: Color(0xFFF6E7CB),
    onPrimary: Color(0xFF06222B),
    playerColors: [
      Color(0xFF0E7C8C),
      Color(0xFF34D399),
      Color(0xFFF6E7CB),
      Color(0xFF3B82F6),
    ],
  ),
  GameTheme(
    id: 'neon',
    name: 'Neon Bazaar',
    tagline: 'Electric street lights',
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF1A1A1A),
    primary: Color(0xFFD400FF),
    secondary: Color(0xFF00F5FF),
    accent: Color(0xFFC8FF3D),
    onPrimary: Color(0xFF0D0D0D),
    playerColors: [
      Color(0xFFFF2E88),
      Color(0xFF00F5FF),
      Color(0xFFC8FF3D),
      Color(0xFFB45CFF),
    ],
  ),
  GameTheme(
    id: 'desert',
    name: 'Desert Caravan',
    tagline: 'Golden dunes at dusk',
    background: Color(0xFF241407),
    surface: Color(0xFF3A2210),
    primary: Color(0xFFB45309),
    secondary: Color(0xFFF59E0B),
    accent: Color(0xFFFEF3C7),
    onPrimary: Color(0xFF241407),
    playerColors: [
      Color(0xFFB45309),
      Color(0xFF65A30D),
      Color(0xFFF59E0B),
      Color(0xFF0EA5E9),
    ],
  ),
  GameTheme(
    id: 'forest',
    name: 'Forest Retreat',
    tagline: 'Emerald calm of the grove',
    background: Color(0xFF0B1F14),
    surface: Color(0xFF14301F),
    primary: Color(0xFF166534),
    secondary: Color(0xFF4ADE80),
    accent: Color(0xFFD9F99D),
    onPrimary: Color(0xFFF0FDF4),
    playerColors: [
      Color(0xFF4ADE80),
      Color(0xFF22D3EE),
      Color(0xFFFACC15),
      Color(0xFFF87171),
    ],
  ),
  GameTheme(
    id: 'mono',
    name: 'Mono Ink',
    tagline: 'Minimal ink on paper',
    background: Color(0xFFF5F2EA),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF1A1A1A),
    secondary: Color(0xFF6B7280),
    accent: Color(0xFFB45309),
    onPrimary: Color(0xFFF5F2EA),
    playerColors: [
      Color(0xFF1A1A1A),
      Color(0xFF6B7280),
      Color(0xFFB45309),
      Color(0xFF0E7490),
    ],
  ),
  GameTheme(
    id: 'sunset',
    name: 'Sunset Haveli',
    tagline: 'Amber skies over the fort',
    background: Color(0xFF2B0F1A),
    surface: Color(0xFF3E1626),
    primary: Color(0xFFE8590C),
    secondary: Color(0xFFFFD43B),
    accent: Color(0xFFFF8787),
    onPrimary: Color(0xFF2B0F1A),
    playerColors: [
      Color(0xFFE8590C),
      Color(0xFF66A80F),
      Color(0xFFFFD43B),
      Color(0xFF9775FA),
    ],
  ),
];
