import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import '../models/bucket_item.dart';
import '../screens/settings_screen.dart';
import '../screens/theme_screen.dart';
import '../screens/upgrade_screen.dart';
import '../theme/app_theme.dart';

/// 左からスライドして出る、Twitterのプロフィール風ドロワー
class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      final dir = await profileRepository.storage.photosDir();
      final dest = '${dir.path}/avatar_${const Uuid().v4()}.jpg';
      await File(picked.path).copy(dest);
      await profileRepository.updateAvatar(dest);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真を読み込めませんでした')),
        );
      }
    }
  }

  void _showAvatarOptions() {
    final hasAvatar = profileRepository.profile.avatarPath != null;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera, color: AppTheme.primary),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.accent),
              title: const Text('ライブラリから選択'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            if (hasAvatar)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('写真を削除'),
                onTap: () {
                  Navigator.pop(context);
                  profileRepository.updateAvatar(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName() async {
    final controller =
        TextEditingController(text: profileRepository.profile.name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('名前を編集'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: '名前を入力'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) {
      await profileRepository.updateName(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.bg,
      child: ListenableBuilder(
        listenable: Listenable.merge(
            [profileRepository, bucketRepository, premiumRepository]),
        builder: (context, _) {
          final profile = profileRepository.profile;
          final done = bucketRepository.completedCount;
          final total = bucketRepository.total;
          final percent = ((done / 100) * 100).round();
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(profile.name, profile.avatarPath, done),
              const SizedBox(height: 8),
              _statsRow(done: done, remaining: 100 - done, percent: percent),
              _premiumTile(context, total),
              _themeTile(context),
              _settingsTile(context),
              const Divider(height: 32, indent: 20, endIndent: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    const Text('🏷️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'カテゴリ別の達成',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              ..._categoryBreakdown(bucketRepository.items),
              const SizedBox(height: 24),
              if (total > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    done == total && total > 0
                        ? 'すべて叶えたね。最高の人生だ🏆'
                        : 'あと ${100 - done} 個。叶えていこう🔥',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _header(String name, String? avatarPath, int done) {
    final hasAvatar = avatarPath != null && File(avatarPath).existsSync();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _showAvatarOptions,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        hasAvatar ? FileImage(File(avatarPath)) : null,
                    child: hasAvatar
                        ? null
                        : Icon(Icons.person,
                            size: 44, color: AppTheme.primary),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    child: Icon(Icons.photo_camera,
                        size: 16, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _editName,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name.isEmpty ? '名前を設定' : name,
                    style: TextStyle(
                      color: name.isEmpty ? Colors.white70 : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit, size: 16, color: Colors.white70),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '人生でやりたい100のこと、$done個達成🎉',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _statsRow({
    required int done,
    required int remaining,
    required int percent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _stat('達成', '$done'),
          _statDivider(),
          _stat('残り', '$remaining'),
          _statDivider(),
          _stat('達成率', '$percent%'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.ink.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        color: AppTheme.border,
      );

  /// テーマ選択への導線。現在のテーマ名を表示。
  Widget _themeTile(BuildContext context) {
    final current = themeRepository.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pop(); // ドロワーを閉じる
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThemeScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'テーマ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                Text(
                  '${current.emoji} ${current.name}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 設定（リマインダー・バックアップ）への導線。
  Widget _settingsTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pop(); // ドロワーを閉じる
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text('⚙️', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '設定',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                Text(
                  'リマインダー・バックアップ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// デバッグ専用：プレミアムをテスト解放/解除する。
  Future<void> _debugTogglePremium(BuildContext context) async {
    final next = !premiumRepository.isPremium;
    await premiumRepository.debugSetPremium(next);
    // 解除時に限定テーマが残らないようデフォルトへ戻す。
    if (!next && themeRepository.current.premium) {
      await themeRepository.select(AppPalettes.classic);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next ? '【テスト】プレミアム解放' : '【テスト】プレミアム解除'),
        ),
      );
    }
  }

  /// プレミアムへの導線（購入済みなら状態表示）。
  Widget _premiumTile(BuildContext context, int total) {
    final isPremium = premiumRepository.isPremium;
    final remaining = premiumRepository.remainingFreeSlots(total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Material(
        color: isPremium ? AppTheme.premiumTint : AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // デバッグビルド限定：長押しでプレミアムを解放/解除（実機検証用）。
          onLongPress: kDebugMode ? () => _debugTogglePremium(context) : null,
          onTap: isPremium
              ? null
              : () {
                  Navigator.of(context).pop(); // ドロワーを閉じる
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? 'プレミアム会員' : 'ユメツミ プレミアム',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPremium
                            ? '100個まで登録できます。ありがとう🎉'
                            : '残り$remaining個。100個まで解放しよう',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.ink.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPremium)
                  Icon(Icons.chevron_right, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _categoryBreakdown(List<BucketItem> items) {
    return BucketCategory.all.map((c) {
      final inCat = items.where((e) => e.categoryId == c.id).toList();
      final total = inCat.length;
      final done = inCat.where((e) => e.completed).length;
      final ratio = total == 0 ? 0.0 : done / total;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                '${c.emoji} ${c.label}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: AppTheme.subtle,
                  valueColor: AlwaysStoppedAnimation(c.color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 40,
              child: Text(
                '$done/$total',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
