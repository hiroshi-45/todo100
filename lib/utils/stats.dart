import '../models/bucket_item.dart';

/// ホームヘッダーに出す、達成状況に応じた応援ひとこと。
///
/// - [done]: これまでの達成数（0〜100想定）
/// - [monthCount]: 今月の達成数
///
/// 「今月の勢い」を最優先で伝え、なければ到達フェーズに応じて変化させる。
String encouragementMessage(int done, int monthCount) {
  if (done >= 100) return 'コンプリート！最高の人生だ🏆';
  if (done <= 0) return 'さあ、最初のひとつを叶えよう🔥';

  final remaining = 100 - done;
  if (monthCount > 0) {
    return '今月 $monthCount個達成！この調子🔥';
  }
  if (remaining <= 10) return 'ゴールまであと$remaining個！🏁';
  if (done >= 50) return '折り返し通過。いい人生だ✨';
  if (done >= 25) return '1/4クリア。波に乗ってきた🌊';
  if (done >= 10) return 'ふた桁達成、絶好調🙌';
  return 'あと$remaining個、叶えていこう👏';
}

/// 達成タイムラインの「ひと月分」のまとまり。
class TimelineSection {
  TimelineSection({required this.monthKey, required this.items});

  /// その月を表す日時（年・月のみ）。達成日未設定の項目は null。
  final DateTime? monthKey;
  final List<BucketItem> items;

  /// 「2026年1月」などの見出しラベル。日付未設定は専用ラベル。
  String get label => monthKey == null
      ? '達成日の記録なし'
      : '${monthKey!.year}年${monthKey!.month}月';
}

/// 達成済み項目を「達成日の新しい月順」に並べ、月ごとにまとめる。
///
/// - 達成済みでない項目は除外する。
/// - 同じ月の中は達成日の新しい順。
/// - 達成日が未設定の項目は末尾の専用セクションにまとめる。
List<TimelineSection> buildTimeline(List<BucketItem> items) {
  final completed = items.where((e) => e.completed).toList();
  completed.sort((a, b) {
    final ad = a.completedDate;
    final bd = b.completedDate;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1; // 日付なしは後ろへ
    if (bd == null) return -1;
    return bd.compareTo(ad); // 新しい順
  });

  final sections = <TimelineSection>[];
  for (final item in completed) {
    final d = item.completedDate;
    final key = d == null ? null : DateTime(d.year, d.month);
    if (sections.isEmpty || sections.last.monthKey != key) {
      sections.add(TimelineSection(monthKey: key, items: []));
    }
    sections.last.items.add(item);
  }
  return sections;
}
