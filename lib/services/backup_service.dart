import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bucket_item.dart';
import '../models/profile.dart';
import 'storage_service.dart';

/// バックアップから読み出したデータ一式（写真は端末側に展開済み）。
class BackupData {
  BackupData({required this.items, required this.profile});
  final List<BucketItem> items;
  final Profile profile;
}

/// やりたいことリスト・プロフィール・写真をまとめて zip に書き出し／読み込みする。
///
/// 写真は端末ごとに絶対パスが変わるため、zip 内ではファイル名（basename）で
/// 格納し、復元時に新しい写真フォルダへ展開してパスを貼り直す。これにより
/// 機種変更・再インストールをまたいでも写真ごと復元できる。
class BackupService {
  BackupService(this._storage);

  final StorageService _storage;

  static const _itemsEntry = 'bucket_list.json';
  static const _profileEntry = 'profile.json';
  static const _photosPrefix = 'photos/';

  /// バックアップ zip を作って共有シートを開く。
  /// 書き出しに成功すれば true。
  Future<bool> exportAndShare(List<BucketItem> items, Profile profile) async {
    try {
      final archive = Archive();

      // 本体データ（JSON）。
      _addString(archive, _itemsEntry,
          jsonEncode(items.map((e) => e.toJson()).toList()));
      _addString(archive, _profileEntry, jsonEncode(profile.toJson()));

      // 参照されている写真を basename で同梱（重複は一度だけ）。
      final added = <String>{};
      for (final item in items) {
        await _addPhoto(archive, item.photoPath, added);
      }
      await _addPhoto(archive, profile.avatarPath, added);

      final bytes = ZipEncoder().encode(archive);
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final dir = await getTemporaryDirectory();
      final out = File('${dir.path}/yumetsumi_backup_$stamp.zip');
      await out.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(out.path)],
          text: 'ユメツミのバックアップ（$stamp）',
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// バックアップ zip を読み込み、写真を端末へ展開してデータを返す。
  /// 形式が不正なら null。
  Future<BackupData?> readBackup(File zip) async {
    try {
      final bytes = await zip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 写真を新しい写真フォルダへ展開し、basename→新パスの対応を作る。
      final photosDir = await _storage.photosDir();
      final remap = <String, String>{};
      for (final file in archive) {
        if (!file.isFile || !file.name.startsWith(_photosPrefix)) continue;
        final base = file.name.substring(_photosPrefix.length);
        if (base.isEmpty) continue;
        final dest = File('${photosDir.path}/$base');
        await dest.writeAsBytes(file.content);
        remap[base] = dest.path;
      }

      final itemsJson = _readString(archive, _itemsEntry);
      final profileJson = _readString(archive, _profileEntry);
      if (itemsJson == null) return null;

      final items = (jsonDecode(itemsJson) as List<dynamic>)
          .map((e) => BucketItem.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final item in items) {
        item.photoPath = _remapPath(item.photoPath, remap);
      }

      final profile = profileJson != null
          ? Profile.fromJson(jsonDecode(profileJson) as Map<String, dynamic>)
          : Profile();
      profile.avatarPath = _remapPath(profile.avatarPath, remap);

      return BackupData(items: items, profile: profile);
    } catch (_) {
      return null;
    }
  }

  void _addString(Archive archive, String name, String content) {
    final data = utf8.encode(content);
    archive.addFile(ArchiveFile(name, data.length, data));
  }

  String? _readString(Archive archive, String name) {
    for (final file in archive) {
      if (file.isFile && file.name == name) {
        return utf8.decode(file.content);
      }
    }
    return null;
  }

  Future<void> _addPhoto(
      Archive archive, String? path, Set<String> added) async {
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;
    final base = _basename(path);
    if (added.contains(base)) return;
    final data = await file.readAsBytes();
    archive.addFile(ArchiveFile('$_photosPrefix$base', data.length, data));
    added.add(base);
  }

  /// 旧パスの basename を、展開済みの新パスに貼り替える。見つからなければ null。
  String? _remapPath(String? oldPath, Map<String, String> remap) {
    if (oldPath == null) return null;
    return remap[_basename(oldPath)];
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last
      .split('/')
      .last;
}
