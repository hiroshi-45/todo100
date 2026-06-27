import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';

/// 設定画面：達成リマインダー（通知）とバックアップ（書き出し／読み込み）。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleReminders(bool value) async {
    final ok = await settingsRepository.setRemindersEnabled(value);
    if (value && !ok) {
      _toast('通知が許可されていません。端末の設定からオンにしてください');
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: settingsRepository.reminderTime,
    );
    if (picked != null) {
      await settingsRepository.setReminderTime(picked);
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final ok = await backupService.exportAndShare(
      bucketRepository.items,
      profileRepository.profile,
    );
    if (mounted) setState(() => _busy = false);
    if (!ok) _toast('バックアップの書き出しに失敗しました');
  }

  Future<void> _import() async {
    const typeGroup = XTypeGroup(
      label: 'バックアップ',
      extensions: ['zip'],
      // iOS は UTI も指定しておくと zip を選びやすい。
      uniformTypeIdentifiers: ['public.zip-archive'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    setState(() => _busy = true);
    final data = await backupService.readBackup(File(file.path));
    if (mounted) setState(() => _busy = false);
    if (data == null) {
      _toast('このファイルは読み込めませんでした');
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('バックアップから復元'),
        content: Text(
          '${data.items.length}件のやりたいことを読み込みます。\n'
          '現在のデータは置き換えられます。よろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('復元する'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await bucketRepository.replaceAll(data.items);
    await profileRepository.replaceProfile(data.profile);
    _toast('復元しました🎉');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: settingsRepository,
          builder: (context, _) {
            final t = settingsRepository.reminderTime;
            final timeLabel =
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const _SectionTitle('🔔 リマインダー'),
                _Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('毎日リマインドする',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('やりたいことを思い出すやさしい通知'),
                        value: settingsRepository.remindersEnabled,
                        onChanged: _busy ? null : _toggleReminders,
                      ),
                      if (settingsRepository.remindersEnabled)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.schedule, color: AppTheme.primary),
                          title: const Text('通知する時刻'),
                          trailing: Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          onTap: _pickTime,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('💾 バックアップ'),
                _Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(Icons.ios_share, color: AppTheme.primary),
                        title: const Text('バックアップを書き出す',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle:
                            const Text('リストと写真をまとめて保存・共有'),
                        onTap: _busy ? null : _export,
                      ),
                      Divider(color: AppTheme.border, height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.download_outlined,
                            color: AppTheme.accent),
                        title: const Text('バックアップから復元',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('書き出したファイルを読み込む'),
                        onTap: _busy ? null : _import,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '機種変更や再インストールの前に書き出しておくと安心です。'
                    '写真も一緒に保存されます。',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppTheme.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (_busy) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppTheme.ink,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
