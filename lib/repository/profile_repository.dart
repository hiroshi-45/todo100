import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import '../services/storage_service.dart';

/// プロフィール（名前・顔写真）の状態を管理する
class ProfileRepository extends ChangeNotifier {
  ProfileRepository(this._storage);

  final StorageService _storage;
  Profile _profile = Profile();
  bool _loaded = false;

  Profile get profile => _profile;
  bool get loaded => _loaded;
  StorageService get storage => _storage;

  Future<void> init() async {
    _profile = await _storage.loadProfile();
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    _profile.name = name.trim();
    notifyListeners();
    await _storage.saveProfile(_profile);
  }

  /// 顔写真を設定する。古い写真は削除する。
  /// [path] が null の場合は写真を削除する。
  Future<void> updateAvatar(String? path) async {
    final old = _profile.avatarPath;
    if (old != null && old != path) {
      final file = File(old);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    _profile.avatarPath = path;
    notifyListeners();
    await _storage.saveProfile(_profile);
  }
}
