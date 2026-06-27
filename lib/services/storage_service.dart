import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/bucket_item.dart';
import '../models/profile.dart';

/// やりたいことリストをローカルのJSONファイルに保存・読み込みする
class StorageService {
  static const _fileName = 'bucket_list.json';
  static const _profileFileName = 'profile.json';
  static const _premiumFileName = 'premium.json';
  static const _themeFileName = 'theme.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<File> _profileFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_profileFileName');
  }

  Future<File> _premiumFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_premiumFileName');
  }

  Future<File> _themeFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_themeFileName');
  }

  /// 写真などを保存するアプリ専用ディレクトリ
  Future<Directory> photosDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final photos = Directory('${dir.path}/photos');
    if (!await photos.exists()) {
      await photos.create(recursive: true);
    }
    return photos;
  }

  Future<List<BucketItem>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final List<dynamic> data = jsonDecode(content) as List<dynamic>;
      return data
          .map((e) => BucketItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<BucketItem> items) async {
    final file = await _file();
    final data = items.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  Future<Profile> loadProfile() async {
    try {
      final file = await _profileFile();
      if (!await file.exists()) return Profile();
      final content = await file.readAsString();
      if (content.trim().isEmpty) return Profile();
      return Profile.fromJson(jsonDecode(content) as Map<String, dynamic>);
    } catch (_) {
      return Profile();
    }
  }

  Future<void> saveProfile(Profile profile) async {
    final file = await _profileFile();
    await file.writeAsString(jsonEncode(profile.toJson()));
  }

  /// プレミアム購入状態をローカルにキャッシュする。
  /// 起動時にオフラインでも素早く解放状態を判定するための保険であり、
  /// 真の購入状態はストアの復元（restorePurchases）で再確認される。
  Future<bool> loadPremium() async {
    try {
      final file = await _premiumFile();
      if (!await file.exists()) return false;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return false;
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['premium'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> savePremium(bool value) async {
    final file = await _premiumFile();
    await file.writeAsString(jsonEncode({'premium': value}));
  }

  /// 選択中テーマのID。未保存なら null。
  Future<String?> loadThemeId() async {
    try {
      final file = await _themeFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['themeId'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveThemeId(String id) async {
    final file = await _themeFile();
    await file.writeAsString(jsonEncode({'themeId': id}));
  }
}
