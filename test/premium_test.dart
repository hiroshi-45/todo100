import 'package:flutter_test/flutter_test.dart';
import 'package:zom100/repository/premium_repository.dart';
import 'package:zom100/services/storage_service.dart';

void main() {
  group('PremiumRepository 無料プランの上限ロジック', () {
    late PremiumRepository repo;

    setUp(() {
      // init() を呼ばないので未購入（無料）状態のまま検証する。
      repo = PremiumRepository(StorageService());
    });

    test('上限未満なら追加できる', () {
      expect(repo.canAdd(0), isTrue);
      expect(repo.canAdd(kFreeItemLimit - 1), isTrue);
    });

    test('ちょうど上限に達したら追加できない', () {
      expect(repo.canAdd(kFreeItemLimit), isFalse);
    });

    test('上限を超えていても（既存データが多い場合）追加できない', () {
      expect(repo.canAdd(kFreeItemLimit + 5), isFalse);
    });

    test('残り枠は上限から現在数を引いた値', () {
      expect(repo.remainingFreeSlots(0), kFreeItemLimit);
      expect(repo.remainingFreeSlots(kFreeItemLimit - 3), 3);
    });

    test('残り枠は負にならず0で下げ止まる', () {
      expect(repo.remainingFreeSlots(kFreeItemLimit), 0);
      expect(repo.remainingFreeSlots(kFreeItemLimit + 10), 0);
    });

    test('未購入の初期状態では isPremium は false', () {
      expect(repo.isPremium, isFalse);
    });
  });
}
