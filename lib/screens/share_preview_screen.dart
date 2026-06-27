import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bucket_item.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';

/// 達成した項目を「シェア用カード画像」にして共有する画面。
///
/// 画面に表示しているカード（[RepaintBoundary] でラップ）をそのまま
/// PNG 化して OS の共有シートに渡す。プレミアム限定機能。
class SharePreviewScreen extends StatefulWidget {
  const SharePreviewScreen({
    super.key,
    required this.item,
    required this.achievedCount,
  });

  final BucketItem item;

  /// これまでの達成総数（カードのフッターに添える）。
  final int achievedCount;

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;
  bool _imageReady = false;

  bool get _hasPhoto {
    final p = widget.item.photoPath;
    return p != null && File(p).existsSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 写真をキャプチャ前に読み込んでおく（書き出し画像の欠けを防ぐ）。
    if (_hasPhoto && !_imageReady) {
      precacheImage(FileImage(File(widget.item.photoPath!)), context)
          .whenComplete(() {
        if (mounted) setState(() => _imageReady = true);
      });
    } else {
      _imageReady = true;
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    final ok = await shareService.shareBoundary(
      _cardKey,
      text: '「${widget.item.title}」を叶えた！ #ユメツミ #やりたいことリスト100',
    );
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像を作成できませんでした。もう一度お試しください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canShare = _imageReady && !_sharing;
    return Scaffold(
      appBar: AppBar(title: const Text('シェア画像')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _ShareCard(
                      item: widget.item,
                      achievedCount: widget.achievedCount,
                      hasPhoto: _hasPhoto,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: canShare ? _share : null,
                  icon: _sharing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.ios_share),
                  label: const Text(
                    'シェアする',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 書き出される実体のカード。SNS映えする縦長デザイン。
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.item,
    required this.achievedCount,
    required this.hasPhoto,
  });

  final BucketItem item;
  final int achievedCount;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final date = item.completedDate;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ビジュアル部：写真があれば写真、なければカテゴリ色のグラデ。
          AspectRatio(
            aspectRatio: 4 / 3,
            child: hasPhoto
                ? Image.file(File(item.photoPath!), fit: BoxFit.cover)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(category.emoji,
                          style: const TextStyle(fontSize: 64)),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${category.emoji} ${category.label}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: category.color,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      date != null
                          ? '${DateFormat('yyyy年M月d日').format(date)} 達成'
                          : '達成',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppTheme.ink.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('✨',
                        style: TextStyle(
                            fontSize: 16, color: AppTheme.primary)),
                    const SizedBox(width: 6),
                    Text(
                      'ユメツミ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '人生でやりたい100のうち $achievedCount個目',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
