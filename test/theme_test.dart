import 'package:flutter_test/flutter_test.dart';
import 'package:zom100/repository/premium_repository.dart';
import 'package:zom100/repository/theme_repository.dart';
import 'package:zom100/services/storage_service.dart';
import 'package:zom100/theme/app_theme.dart';

void main() {
  group('ThemeRepository テーマの利用権', () {
    late ThemeRepository repo;

    setUp(() {
      // init() を呼ばないので未購入（無料）状態のまま検証する。
      final storage = StorageService();
      repo = ThemeRepository(storage, PremiumRepository(storage));
    });

    test('無料（デフォルト）テーマは誰でも使える', () {
      expect(repo.canUse(AppPalettes.classic), isTrue);
    });

    test('プレミアム限定テーマは非会員には使えない', () {
      for (final p in AppPalettes.all.where((p) => p.premium)) {
        expect(repo.canUse(p), isFalse, reason: '${p.name} は無料では選べないはず');
      }
    });

    test('デフォルト以外はすべてプレミアム限定として定義されている', () {
      expect(AppPalettes.classic.premium, isFalse);
      final others = AppPalettes.all.where((p) => p.id != AppPalettes.classic.id);
      expect(others.every((p) => p.premium), isTrue);
    });

    test('パレットIDは一意', () {
      final ids = AppPalettes.all.map((p) => p.id).toSet();
      expect(ids.length, AppPalettes.all.length);
    });

    test('byId は不明なIDでデフォルトに落ちる', () {
      expect(AppPalettes.byId('does_not_exist').id, AppPalettes.classic.id);
    });
  });
}
