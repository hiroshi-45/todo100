import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/bucket_item.dart';
import '../theme/app_theme.dart';
import '../utils/stats.dart';
import 'detail_screen.dart';

/// 達成した項目だけを、達成日順のタイムライン＋写真ギャラリーで
/// 振り返るための画面。「叶えた記録を眺める」楽しさを担う。
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  void _openDetail(BuildContext context, String itemId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(itemId: itemId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('達成の記録',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([bucketRepository, themeRepository]),
          builder: (context, _) {
            final sections = buildTimeline(bucketRepository.items);
            final completed =
                sections.expand((s) => s.items).toList(growable: false);
            if (completed.isEmpty) {
              return const _EmptyGallery();
            }
            final withPhotos = completed
                .where((e) =>
                    e.photoPath != null && File(e.photoPath!).existsSync())
                .toList(growable: false);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _SummaryCard(
                  achieved: completed.length,
                  photos: withPhotos.length,
                ),
                if (withPhotos.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('📸 写真の思い出'),
                  const SizedBox(height: 10),
                  _PhotoStrip(
                    items: withPhotos,
                    onTap: (item) => _openDetail(context, item.id),
                  ),
                ],
                const SizedBox(height: 20),
                const _SectionTitle('🗓 達成のあゆみ'),
                const SizedBox(height: 4),
                for (final section in sections)
                  _TimelineSectionView(
                    section: section,
                    onTapItem: (item) => _openDetail(context, item.id),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.achieved, required this.photos});

  final int achieved;
  final int photos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _metric('叶えた数', '$achieved'),
          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _metric('写真の記録', '$photos'),
          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _metric('達成率', '${((achieved / 100) * 100).round()}%'),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.ink,
      ),
    );
  }
}

/// 写真つき達成項目の横スクロールサムネイル列。
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.items, required this.onTap});

  final List<BucketItem> items;
  final ValueChanged<BucketItem> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => onTap(item),
            child: SizedBox(
              width: 108,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(item.photoPath!),
                      width: 108,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimelineSectionView extends StatelessWidget {
  const _TimelineSectionView({required this.section, required this.onTapItem});

  final TimelineSection section;
  final ValueChanged<BucketItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
          child: Row(
            children: [
              Text(
                section.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppTheme.border,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${section.items.length}個',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        for (final item in section.items)
          _TimelineCard(item: item, onTap: () => onTapItem(item)),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.item, required this.onTap});

  final BucketItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final date = item.completedDate;
    final hasPhoto =
        item.photoPath != null && File(item.photoPath!).existsSync();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: category.color,
                  ),
                  child:
                      const Icon(Icons.check, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
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
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${category.emoji} ${category.label}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: category.color,
                            ),
                          ),
                          if (date != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('M月d日').format(date),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.ink.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasPhoto) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(item.photoPath!),
                      width: 48,
                      height: 48,
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

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'まだ達成した記録がありません',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ひとつ叶えると、ここに\nあゆみと思い出が並んでいきます',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
