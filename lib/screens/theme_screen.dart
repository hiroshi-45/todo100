import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import 'upgrade_screen.dart';

/// テーマ（配色）を選ぶ画面。
///
/// 無料はデフォルトのみ。プレミアム限定テーマはロック表示し、
/// タップでプレミアム案内へ誘導する。
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  Future<void> _onTap(BuildContext context, AppPalette palette) async {
    if (themeRepository.canUse(palette)) {
      await themeRepository.select(palette);
      // 選択したら前の画面に戻り、適用後の見た目を見せる。
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    // プレミアム限定テーマを非会員がタップ → 課金案内へ。
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('テーマ')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([themeRepository, premiumRepository]),
          builder: (context, _) {
            final palettes = themeRepository.all;
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
              ),
              itemCount: palettes.length,
              itemBuilder: (context, i) {
                final p = palettes[i];
                return _ThemeCard(
                  palette: p,
                  selected: themeRepository.current.id == p.id,
                  locked: !themeRepository.canUse(p),
                  onTap: () => _onTap(context, p),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.palette,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? palette.primary : const Color(0xFFEEE2D8),
            width: selected ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // プレビュー（ヘッダー風グラデ＋差し色のドット）
            Expanded(
              child: Stack(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [palette.primary, palette.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Row(
                      children: [
                        _dot(palette.secondary),
                        const SizedBox(width: 6),
                        _dot(palette.accent),
                      ],
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.check,
                            size: 18, color: Colors.black87),
                      ),
                    ),
                  if (locked)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.28),
                        child: const Center(
                          child: Icon(Icons.lock,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Text(palette.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      palette.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (palette.premium && locked)
                    const Text('✨', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
