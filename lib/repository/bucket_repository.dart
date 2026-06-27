import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/bucket_item.dart';
import '../services/storage_service.dart';

/// アプリ全体の状態（やりたいことリスト）を管理する
class BucketRepository extends ChangeNotifier {
  BucketRepository(this._storage);

  final StorageService _storage;
  final List<BucketItem> _items = [];
  bool _loaded = false;

  StorageService get storage => _storage;

  List<BucketItem> get items => List.unmodifiable(_items);
  bool get loaded => _loaded;

  int get total => _items.length;
  int get completedCount => _items.where((e) => e.completed).length;
  double get progress => total == 0 ? 0 : completedCount / total;

  /// 今月（端末の現在日時を基準）に達成した件数。
  int get completedThisMonth {
    final now = DateTime.now();
    return _items.where((e) {
      final d = e.completedDate;
      return e.completed &&
          d != null &&
          d.year == now.year &&
          d.month == now.month;
    }).length;
  }

  Future<void> init() async {
    final loaded = await _storage.load();
    _items
      ..clear()
      ..addAll(loaded);
    _sort();
    _loaded = true;
    notifyListeners();
  }

  /// 未達成を上に、達成済みを下に。同グループ内は作成順。
  void _sort() {
    _items.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  BucketItem? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> add(BucketItem item) async {
    _items.add(item);
    _sort();
    notifyListeners();
    await _persist();
  }

  Future<void> update(BucketItem item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index == -1) return;
    _items[index] = item;
    _sort();
    notifyListeners();
    await _persist();
  }

  /// 達成状態を切り替える。「未達成→達成」になった場合のみ true を返す
  /// （達成演出を出すかどうかの判定に使う）。
  Future<bool> toggleComplete(String id) async {
    final item = byId(id);
    if (item == null) return false;
    item.completed = !item.completed;
    item.completedDate = item.completed ? DateTime.now() : null;
    final becameComplete = item.completed;
    _sort();
    notifyListeners();
    await _persist();
    return becameComplete;
  }

  Future<void> delete(String id) async {
    final item = byId(id);
    if (item == null) return;
    // 添付写真も削除
    final path = item.photoPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() => _storage.save(_items);
}
