import 'package:flutter/material.dart';

/// アプリの配色一式（テーマ1つ分）。
class AppPalette {
  final String id;
  final String name;
  final String emoji;

  /// プレミアム限定テーマか（無料はデフォルトのみ）。
  final bool premium;

  final Color primary; // 主役のブランドカラー
  final Color secondary; // 進捗バーなどの差し色
  final Color accent; // 補助の差し色
  final Color orange; // ヘッダーグラデの相方
  final Color bg; // 背景
  final Color ink; // 文字

  const AppPalette({
    required this.id,
    required this.name,
    required this.emoji,
    required this.premium,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.orange,
    required this.bg,
    required this.ink,
  });
}

/// 選べるテーマの一覧。先頭が無料デフォルト、それ以外はプレミアム限定。
class AppPalettes {
  AppPalettes._();

  static const AppPalette classic = AppPalette(
    id: 'classic',
    name: 'クラシック',
    emoji: '🍅',
    premium: false,
    primary: Color(0xFFEE3124),
    secondary: Color(0xFFFFCB2D),
    accent: Color(0xFF2BB7FF),
    orange: Color(0xFFFF8A3D),
    bg: Color(0xFFFFF8F0),
    ink: Color(0xFF22314A),
  );

  static const AppPalette sakura = AppPalette(
    id: 'sakura',
    name: 'サクラ',
    emoji: '🌸',
    premium: true,
    primary: Color(0xFFFF5C8A),
    secondary: Color(0xFFFFC2D6),
    accent: Color(0xFFFF8FB3),
    orange: Color(0xFFFF8FA3),
    bg: Color(0xFFFFF5F8),
    ink: Color(0xFF4A2233),
  );

  static const AppPalette ocean = AppPalette(
    id: 'ocean',
    name: 'オーシャン',
    emoji: '🌊',
    premium: true,
    primary: Color(0xFF1E88E5),
    secondary: Color(0xFF4DD0E1),
    accent: Color(0xFF00ACC1),
    orange: Color(0xFF26C6DA),
    bg: Color(0xFFF0F8FF),
    ink: Color(0xFF14324A),
  );

  static const AppPalette forest = AppPalette(
    id: 'forest',
    name: 'フォレスト',
    emoji: '🌳',
    premium: true,
    primary: Color(0xFF2E9E5B),
    secondary: Color(0xFFA5D66A),
    accent: Color(0xFF4CAF50),
    orange: Color(0xFF7CB342),
    bg: Color(0xFFF3FAF3),
    ink: Color(0xFF1E3A24),
  );

  static const AppPalette grape = AppPalette(
    id: 'grape',
    name: 'グレープ',
    emoji: '🍇',
    premium: true,
    primary: Color(0xFF8E5BD6),
    secondary: Color(0xFFC9A7F0),
    accent: Color(0xFFB388FF),
    orange: Color(0xFFA66BE0),
    bg: Color(0xFFF8F4FF),
    ink: Color(0xFF2E2240),
  );

  static const AppPalette nightBlue = AppPalette(
    id: 'night_blue',
    name: 'ナイトブルー',
    emoji: '🌌',
    premium: true,
    primary: Color(0xFF3F51B5),
    secondary: Color(0xFF9FA8DA),
    accent: Color(0xFF5C6BC0),
    orange: Color(0xFF7986CB),
    bg: Color(0xFFEEF1FA),
    ink: Color(0xFF1A2233),
  );

  static const List<AppPalette> all = [
    classic,
    sakura,
    ocean,
    forest,
    grape,
    nightBlue,
  ];

  static AppPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => classic);
}

/// アプリの配色テーマ。
///
/// 各色は「現在選択中のパレット」に委譲する（[palette] で差し替え可能）。
/// 既存コードの `AppTheme.primary` などはそのまま使えるが、コンパイル時定数では
/// なくなった点に注意（const 文脈では使えない）。
class AppTheme {
  AppTheme._();

  /// 現在選択中のパレット。[ThemeRepository] が切り替える。
  static AppPalette palette = AppPalettes.classic;

  static Color get primary => palette.primary;
  static Color get secondary => palette.secondary;
  static Color get accent => palette.accent;
  static Color get orange => palette.orange;
  static Color get bg => palette.bg;
  static Color get ink => palette.ink;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Hiragino Sans',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: ink,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEEE2D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
