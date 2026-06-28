import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/bucket_item.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration.dart';
import 'edit_screen.dart';
import 'share_preview_screen.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.itemId});

  final String itemId;

  Future<void> _toggle(BuildContext context) async {
    final becameComplete = await bucketRepository.toggleComplete(itemId);
    if (becameComplete && context.mounted) {
      await showCelebration(context,
          completedCount: bucketRepository.completedCount);
    }
  }

  /// 達成カードのシェア画像を作る（無料で利用可）。
  Future<void> _share(BuildContext context, BucketItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharePreviewScreen(
          item: item,
          achievedCount: bucketRepository.completedCount,
        ),
      ),
    );
  }

  /// 達成日を手動で編集する（後追いで記録できるように）。
  Future<void> _editCompletedDate(BuildContext context, BucketItem item) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: item.completedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: '達成日を選ぶ',
    );
    if (picked != null) {
      await bucketRepository.setCompletedDate(item.id, picked);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    // 画面を閉じても通知を出せるよう、アプリ全体のメッセンジャーを先に取得。
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('削除しますか？'),
        content: const Text('この項目を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final removed = await bucketRepository.delete(itemId);
    navigator.pop();
    if (removed == null) return;

    var undone = false;
    // 既存（表示中・待機中）の SnackBar をクリアしてから最新の1件を出す。
    messenger.clearSnackBars();
    messenger
        .showSnackBar(
          SnackBar(
            content: const Text('削除しました'),
            action: SnackBarAction(
              label: '元に戻す',
              onPressed: () {
                undone = true;
                bucketRepository.restore(removed);
              },
            ),
          ),
        )
        .closed
        .then((_) {
      // 取り消されなければ、ここで初めて添付写真を実際に消す。
      if (!undone) bucketRepository.purgePhoto(removed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([bucketRepository, themeRepository]),
      builder: (context, _) {
        final item = bucketRepository.byId(itemId);
        if (item == null) {
          // 削除済み
          return const Scaffold(body: SizedBox.shrink());
        }
        final category = item.category;
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (!item.completed)
                IconButton(
                  icon: Icon(item.pinned
                      ? Icons.push_pin
                      : Icons.push_pin_outlined),
                  tooltip: item.pinned ? 'ピンを外す' : '次に叶えたい（ピン留め）',
                  color: item.pinned ? AppTheme.primary : null,
                  onPressed: () => bucketRepository.togglePinned(item.id),
                ),
              if (item.completed)
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'シェア画像を作る',
                  onPressed: () => _share(context, item),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditScreen(item: item)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${category.emoji} ${category.label}',
                          style: TextStyle(
                              color: category.color,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (!item.completed && item.pinned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text('次に叶えたい',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    decoration: item.completed
                        ? TextDecoration.lineThrough
                        : null,
                    color: item.completed
                        ? AppTheme.ink.withValues(alpha: 0.5)
                        : AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 20),
                if (item.photoPath != null &&
                    File(item.photoPath!).existsSync()) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(item.photoPath!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (item.memo.trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 18,
                                color: AppTheme.ink.withValues(alpha: 0.6)),
                            const SizedBox(width: 6),
                            Text('メモ・想い',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        AppTheme.ink.withValues(alpha: 0.6))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(item.memo,
                            style: const TextStyle(fontSize: 15, height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (item.completed)
                  InkWell(
                    onTap: () => _editCompletedDate(context, item),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.completedDate != null
                                  ? '達成日：${DateFormat('yyyy年M月d日').format(item.completedDate!)}'
                                  : '達成日を記録する',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: category.color),
                            ),
                          ),
                          Icon(Icons.edit_calendar,
                              size: 18, color: category.color),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _toggle(context),
                    icon: Icon(item.completed
                        ? Icons.refresh
                        : Icons.check_circle),
                    label: Text(
                      item.completed ? '達成を取り消す' : '達成にする！',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          item.completed ? Colors.grey.shade400 : category.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
