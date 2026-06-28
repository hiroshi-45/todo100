import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import '../models/bucket_item.dart';
import '../theme/app_theme.dart';
import '../utils/stats.dart';
import '../utils/wish_examples.dart';
import '../widgets/celebration.dart';
import '../widgets/profile_drawer.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';
import 'gallery_screen.dart';
import 'upgrade_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 達成状況による絞り込み
enum _StatusFilter { all, active, done }

class _HomeScreenState extends State<HomeScreen> {
  String? _filterCategoryId; // null = すべて
  _StatusFilter _statusFilter = _StatusFilter.all;
  String _query = ''; // 検索キーワード（タイトル・メモを対象）

  List<BucketItem> _visible(List<BucketItem> all) {
    final q = _query.trim().toLowerCase();
    return all.where((item) {
      if (_filterCategoryId != null && item.categoryId != _filterCategoryId) {
        return false;
      }
      if (q.isNotEmpty &&
          !item.title.toLowerCase().contains(q) &&
          !item.memo.toLowerCase().contains(q)) {
        return false;
      }
      switch (_statusFilter) {
        case _StatusFilter.active:
          if (item.completed) return false;
          break;
        case _StatusFilter.done:
          if (!item.completed) return false;
          break;
        case _StatusFilter.all:
          break;
      }
      return true;
    }).toList();
  }

  Future<void> _toggle(BucketItem item) async {
    final becameComplete = await bucketRepository.toggleComplete(item.id);
    if (becameComplete && mounted) {
      await showCelebration(context,
          completedCount: bucketRepository.completedCount);
    }
  }

  /// 空状態の候補チップから、ワンタップで1件追加する。
  /// 無料上限に達している場合はプレミアム案内へ。
  Future<void> _quickAdd(String title) async {
    if (!premiumRepository.canAdd(bucketRepository.total)) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UpgradeScreen()),
      );
      return;
    }
    await bucketRepository.add(
      BucketItem(
        id: const Uuid().v4(),
        title: title,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// スワイプ削除：取り消し（Undo）つき。
  void _deleteWithUndo(BucketItem item) {
    final messenger = ScaffoldMessenger.of(context);
    bucketRepository.delete(item.id).then((removed) {
      if (removed == null) return;
      var undone = false;
      // 連続削除でバナーがキューに溜まり出っぱなしに見えるのを防ぐため、
      // 既存（表示中・待機中）の SnackBar をクリアしてから最新の1件を出す。
      messenger.clearSnackBars();
      messenger
          .showSnackBar(
            SnackBar(
              content: Text('「${removed.title}」を削除しました'),
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
        if (!undone) bucketRepository.purgePhoto(removed);
      });
    });
  }

  Future<void> _openEdit({BucketItem? item}) async {
    // 新規追加が無料上限を超える場合は、編集ではなくプレミアム案内へ。
    if (item == null && !premiumRepository.canAdd(bucketRepository.total)) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UpgradeScreen()),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ProfileDrawer(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge(
              [bucketRepository, profileRepository, themeRepository]),
          builder: (context, _) {
            final all = bucketRepository.items;
            final visible = _visible(all);
            final remainingFree =
                premiumRepository.remainingFreeSlots(all.length);
            final showUpgradeHint = !premiumRepository.isPremium &&
                all.isNotEmpty &&
                remainingFree <= 3;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header()),
                SliverToBoxAdapter(child: _filters(all)),
                if (all.length >= 6)
                  SliverToBoxAdapter(
                    child: _SearchField(
                      value: _query,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                if (showUpgradeHint)
                  SliverToBoxAdapter(
                    child: _UpgradeHint(
                      remaining: remainingFree,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const UpgradeScreen()),
                      ),
                    ),
                  ),
                if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      hasAny: all.isNotEmpty,
                      searching: _query.trim().isNotEmpty,
                      onPickExample: _quickAdd,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    sliver: SliverList.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final item = visible[i];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: const _DeleteBackground(),
                          onDismissed: (_) => _deleteWithUndo(item),
                          child: _ItemCard(
                            item: item,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(itemId: item.id),
                              ),
                            ),
                            onToggle: () => _toggle(item),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(),
        icon: const Icon(Icons.add),
        label: const Text('追加', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _filters(List<BucketItem> all) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'すべて',
                  emoji: '📋',
                  color: AppTheme.ink,
                  selected: _filterCategoryId == null,
                  onTap: () => setState(() => _filterCategoryId = null),
                ),
                for (final c in BucketCategory.all)
                  _CategoryChip(
                    label: c.label,
                    emoji: c.emoji,
                    color: c.color,
                    selected: _filterCategoryId == c.id,
                    onTap: () => setState(() => _filterCategoryId = c.id),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _StatusFilterBar(
              current: _statusFilter,
              total: all.length,
              done: all.where((e) => e.completed).length,
              onChanged: (f) => setState(() => _statusFilter = f),
            ),
          ),
        ],
      ),
    );
  }
}

/// すべて / 未達成 / 達成済み の切り替えバー
class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.current,
    required this.total,
    required this.done,
    required this.onChanged,
  });

  final _StatusFilter current;
  final int total;
  final int done;
  final ValueChanged<_StatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = total - done;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.subtle,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _segment('すべて', total, _StatusFilter.all),
          _segment('未達成', active, _StatusFilter.active),
          _segment('達成済み', done, _StatusFilter.done),
        ],
      ),
    );
  }

  Widget _segment(String label, int count, _StatusFilter value) {
    final selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppTheme.card : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppTheme.primary
                  : AppTheme.ink.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

/// 進捗ヘッダー
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final done = bucketRepository.completedCount;
    const goal = 100;
    final progress = (done / goal).clamp(0.0, 1.0);
    final monthCount = bucketRepository.completedThisMonth;
    final message = encouragementMessage(done, monthCount);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _AvatarButton(),
              const SizedBox(width: 10),
              Expanded(
                child: monthCount > 0
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: _MonthPill(count: monthCount),
                      )
                    : const Text(
                        'タップ／左スワイプでプロフィール',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
              ),
              _HeaderIconButton(
                icon: Icons.photo_album_outlined,
                tooltip: '達成の記録',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GalleryScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '死ぬまでにやりたい',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                const Text(
                  '100のこと',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    valueColor:
                        AlwaysStoppedAnimation(AppTheme.secondary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '達成 $done / $goal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ProgressRing(progress: progress, label: '${(progress * 100).round()}%'),
        ],
          ),
        ],
      ),
    );
  }
}

/// 今月の達成数を示すヘッダー内のピル。
class _MonthPill extends StatelessWidget {
  const _MonthPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '今月 +$count 🔥',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// ヘッダー右側の半透明アイコンボタン。
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.22),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

/// ヘッダー左上のアバター（タップでプロフィールドロワーを開く）
class _AvatarButton extends StatelessWidget {
  const _AvatarButton();

  @override
  Widget build(BuildContext context) {
    final avatarPath = profileRepository.profile.avatarPath;
    final hasAvatar = avatarPath != null && File(avatarPath).existsSync();
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          backgroundImage: hasAvatar ? FileImage(File(avatarPath)) : null,
          child: hasAvatar
              ? null
              : Icon(Icons.person, size: 20, color: AppTheme.primary),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.label});
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color : AppTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? color : AppTheme.border,
            ),
          ),
          child: Text(
            '$emoji $label',
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onTap,
    required this.onToggle,
  });

  final BucketItem item;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // タップ領域は 44x44 を確保しつつ、見た目の丸は 30px のまま。
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              item.completed ? category.color : AppTheme.card,
                          border: Border.all(color: category.color, width: 2),
                        ),
                        child: item.completed
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: item.completed
                              ? AppTheme.ink.withValues(alpha: 0.4)
                              : AppTheme.ink,
                          decoration: item.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (!item.completed && item.pinned) ...[
                            Icon(Icons.push_pin,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                          ],
                          _Badge(
                            text: '${category.emoji} ${category.label}',
                            color: category.color,
                          ),
                          if (item.memo.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.sticky_note_2_outlined,
                                size: 14,
                                color: AppTheme.ink.withValues(alpha: 0.4)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (item.photoPath != null &&
                    File(item.photoPath!).existsSync()) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(item.photoPath!),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasAny,
    required this.searching,
    required this.onPickExample,
  });

  final bool hasAny;
  final bool searching;
  final ValueChanged<String> onPickExample;

  @override
  Widget build(BuildContext context) {
    // まだ1件もなく、検索中でもないときは「ワンタップ候補」で初速を出す。
    final showStarters = !hasAny && !searching;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(searching ? '🔍' : '🪣', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              hasAny
                  ? (searching ? '見つかりませんでした' : '条件に合う項目がありません')
                  : 'まだ何もありません',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasAny
                  ? (searching ? 'キーワードを変えてみましょう' : 'フィルターを変えてみましょう')
                  : 'まずは気になるものをタップ、\nまたは右下の「追加」から書き出そう！',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.6)),
            ),
            if (showStarters) ...[
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final example in shuffledExamples().take(6))
                    GestureDetector(
                      onTap: () => onPickExample(example),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          '＋ $example',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 検索入力欄。
class _SearchField extends StatelessWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'やりたいことを検索',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(''),
                )
              : null,
        ),
      ),
    );
  }
}

/// 無料枠の残りが少なくなったときに出す、控えめなプレミアム案内。
class _UpgradeHint extends StatelessWidget {
  const _UpgradeHint({required this.remaining, required this.onTap});

  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final atLimit = remaining <= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: AppTheme.premiumTint,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    atLimit
                        ? '無料枠がいっぱいです。プレミアムで100個まで解放しよう'
                        : '無料で追加できるのはあと$remaining個。100個まで解放できます',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// スワイプ削除時に背面に表示する赤い「削除」ボード。
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 6),
          Text('削除',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
