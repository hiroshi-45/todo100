import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'premium_repository.dart';

/// 選択中のテーマ（配色パレット）を管理する。
///
/// 無料ユーザーはデフォルト（[AppPalettes.classic]）のみ。
/// プレミアム限定テーマは [PremiumRepository.isPremium] のときだけ選べる。
class ThemeRepository extends ChangeNotifier {
  ThemeRepository(this._storage, this._premium);

  final StorageService _storage;
  final PremiumRepository _premium;

  String _paletteId = AppPalettes.classic.id;

  AppPalette get current => AppPalettes.byId(_paletteId);
  List<AppPalette> get all => AppPalettes.all;

  /// このテーマを今のユーザーが利用できるか。
  bool canUse(AppPalette palette) => !palette.premium || _premium.isPremium;

  Future<void> init() async {
    final saved = await _storage.loadThemeId();
    if (saved != null) _paletteId = saved;
    // プレミアム失効時などに限定テーマが残らないよう、権利を再確認。
    if (current.premium && !_premium.isPremium) {
      _paletteId = AppPalettes.classic.id;
      await _storage.saveThemeId(_paletteId);
    }
    AppTheme.palette = current;
    notifyListeners();
  }

  /// テーマを選択する。
  /// 利用権がない（プレミアム限定×非会員）場合は何もせず false を返す
  /// （呼び出し側で課金導線へ誘導する）。
  Future<bool> select(AppPalette palette) async {
    if (!canUse(palette)) return false;
    if (palette.id == _paletteId) return true;
    _paletteId = palette.id;
    AppTheme.palette = palette;
    await _storage.saveThemeId(palette.id);
    notifyListeners();
    return true;
  }
}
