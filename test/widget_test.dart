import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zom100/models/bucket_item.dart';
import 'package:zom100/models/profile.dart';
import 'package:zom100/utils/stats.dart';
import 'package:zom100/utils/wish_examples.dart';
import 'package:zom100/widgets/celebration.dart';

void main() {
  group('BucketItem', () {
    test('toJson/fromJson でデータが往復できる', () {
      final item = BucketItem(
        id: 'abc',
        title: 'オーロラを見る',
        categoryId: 'travel',
        memo: 'いつか北欧で',
        completed: true,
        completedDate: DateTime(2026, 1, 2),
        photoPath: '/tmp/photo.jpg',
        createdAt: DateTime(2025, 12, 31),
      );

      final restored = BucketItem.fromJson(item.toJson());

      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.categoryId, item.categoryId);
      expect(restored.memo, item.memo);
      expect(restored.completed, isTrue);
      expect(restored.completedDate, item.completedDate);
      expect(restored.photoPath, item.photoPath);
      expect(restored.createdAt, item.createdAt);
    });

    test('不明なカテゴリIDは「その他」にフォールバックする', () {
      expect(BucketCategory.byId('unknown').id, 'other');
    });

    test('カテゴリゲッターが正しいカテゴリを返す', () {
      final item = BucketItem(
        id: '1',
        title: 't',
        categoryId: 'health',
        createdAt: DateTime.now(),
      );
      expect(item.category.label, '健康');
    });
  });

  group('達成演出 (celebrationInfo)', () {
    test('5の倍数は節目（マイルストーン）になる', () {
      for (final c in [5, 10, 15, 20, 25, 50, 100]) {
        expect(celebrationInfo(c).isMilestone, isTrue, reason: '$c');
      }
    });

    test('5の倍数でない達成は通常演出', () {
      for (final c in [1, 3, 7, 12, 99]) {
        expect(celebrationInfo(c).isMilestone, isFalse, reason: '$c');
      }
    });

    test('達成0件では演出を出さない（節目扱いしない）', () {
      expect(celebrationInfo(0).isMilestone, isFalse);
    });

    test('区切りのよい節目には専用メッセージが入る', () {
      expect(celebrationInfo(50).message, contains('折り返し'));
      expect(celebrationInfo(100).message, contains('コンプリート'));
    });

    test('特別指定のない節目にも達成数入りメッセージが出る', () {
      expect(celebrationInfo(15).message, contains('15個達成'));
    });

    test('通常演出のメッセージは空にならない', () {
      final info = celebrationInfo(7, random: Random(1));
      expect(info.message, isNotEmpty);
    });
  });

  group('encouragementMessage', () {
    test('0個では最初の一歩を促す', () {
      expect(encouragementMessage(0, 0), contains('最初'));
    });

    test('100個でコンプリートを祝う', () {
      expect(encouragementMessage(100, 0), contains('コンプリート'));
    });

    test('今月の達成があれば最優先で勢いを伝える', () {
      final msg = encouragementMessage(40, 3);
      expect(msg, contains('今月'));
      expect(msg, contains('3'));
    });

    test('今月分が0でも到達フェーズに応じた応援が出る', () {
      expect(encouragementMessage(95, 0), contains('5')); // 残り5個
      expect(encouragementMessage(50, 0), contains('折り返し'));
    });

    test('メッセージは常に空にならない', () {
      for (var d = 0; d <= 100; d++) {
        expect(encouragementMessage(d, 0), isNotEmpty, reason: '$d');
      }
    });
  });

  group('buildTimeline', () {
    BucketItem make(String id,
            {bool completed = true, DateTime? date}) =>
        BucketItem(
          id: id,
          title: id,
          completed: completed,
          completedDate: date,
          createdAt: DateTime(2025, 1, 1),
        );

    test('未達成は除外される', () {
      final sections = buildTimeline([
        make('a', completed: false),
        make('b', date: DateTime(2026, 5, 1)),
      ]);
      final all = sections.expand((s) => s.items).map((e) => e.id);
      expect(all, ['b']);
    });

    test('新しい月が先、月ごとにまとまる', () {
      final sections = buildTimeline([
        make('jan', date: DateTime(2026, 1, 10)),
        make('may1', date: DateTime(2026, 5, 2)),
        make('may2', date: DateTime(2026, 5, 20)),
      ]);
      expect(sections.length, 2);
      expect(sections.first.label, '2026年5月');
      expect(sections.first.items.map((e) => e.id), ['may2', 'may1']);
      expect(sections.last.label, '2026年1月');
    });

    test('達成日なしは末尾の専用セクションに入る', () {
      final sections = buildTimeline([
        make('dated', date: DateTime(2026, 3, 1)),
        make('nodate', date: null),
      ]);
      expect(sections.last.monthKey, isNull);
      expect(sections.last.label, '達成日の記録なし');
      expect(sections.last.items.single.id, 'nodate');
    });
  });

  group('shuffledExamples', () {
    test('元のリストを変更しない', () {
      final before = List<String>.of(wishExamples);
      shuffledExamples(Random(1));
      expect(wishExamples, before);
    });

    test('要素は過不足なく同じ（並びだけ変わる）', () {
      final shuffled = shuffledExamples(Random(1));
      expect(shuffled.length, wishExamples.length);
      expect(shuffled.toSet(), wishExamples.toSet());
    });

    test('例文はそれなりの数があり、空文字を含まない', () {
      expect(wishExamples.length, greaterThanOrEqualTo(20));
      expect(wishExamples.any((e) => e.trim().isEmpty), isFalse);
    });

    test('例文に重複がない', () {
      expect(wishExamples.toSet().length, wishExamples.length);
    });
  });

  group('Profile', () {
    test('toJson/fromJson でデータが往復できる', () {
      final p = Profile(name: 'まるの', avatarPath: '/tmp/avatar.jpg');
      final restored = Profile.fromJson(p.toJson());
      expect(restored.name, 'まるの');
      expect(restored.avatarPath, '/tmp/avatar.jpg');
    });

    test('空のJSONからでも安全に生成できる', () {
      final p = Profile.fromJson({});
      expect(p.name, '');
      expect(p.avatarPath, isNull);
    });

    test('clearAvatar でアバターを消せる', () {
      final p = Profile(name: 'x', avatarPath: '/a.jpg');
      final cleared = p.copyWith(clearAvatar: true);
      expect(cleared.avatarPath, isNull);
      expect(cleared.name, 'x');
    });
  });
}
