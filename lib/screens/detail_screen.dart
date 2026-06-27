import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/bucket_item.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration.dart';
import 'edit_screen.dart';
import 'share_preview_screen.dart';
import 'upgrade_screen.dart';

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

  /// 達成カードのシェア画像を書き出す（プレミアム限定）。
  /// 非会員はプレミアム案内へ誘導する。
  Future<void> _share(BuildContext context, BucketItem item) async {
    if (!premiumRepository.isPremium) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UpgradeScreen()),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharePreviewScreen(
          item: item,
          achievedCount: bucketRepository.completedCount,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('削除しますか？'),
        content: const Text('この項目を削除します。元に戻せません。'),
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
    if (ok == true) {
      await bucketRepository.delete(itemId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bucketRepository,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${category.emoji} ${category.label}',
                          style: TextStyle(
                              color: category.color,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
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
                      color: Colors.white,
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
                if (item.completed && item.completedDate != null)
                  Container(
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
                        Text(
                          '達成日：${DateFormat('yyyy年M月d日').format(item.completedDate!)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: category.color),
                        ),
                      ],
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
