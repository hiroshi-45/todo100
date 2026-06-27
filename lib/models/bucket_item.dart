import 'package:flutter/material.dart';

/// カテゴリの定義（絵文字・色つき）
class BucketCategory {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  const BucketCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });

  static const List<BucketCategory> all = [
    BucketCategory(id: 'travel', label: '旅行', emoji: '✈️', color: Color(0xFF4FC3F7)),
    BucketCategory(id: 'challenge', label: '挑戦', emoji: '🔥', color: Color(0xFFFF7043)),
    BucketCategory(id: 'experience', label: '体験', emoji: '🎢', color: Color(0xFFFFCA28)),
    BucketCategory(id: 'learn', label: '学び', emoji: '📚', color: Color(0xFF66BB6A)),
    BucketCategory(id: 'people', label: '人間関係', emoji: '💞', color: Color(0xFFEC407A)),
    BucketCategory(id: 'health', label: '健康', emoji: '💪', color: Color(0xFF26C6DA)),
    BucketCategory(id: 'other', label: 'その他', emoji: '🌟', color: Color(0xFFAB47BC)),
  ];

  static BucketCategory byId(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => all.last,
    );
  }
}

/// やりたいこと1件分のデータ
class BucketItem {
  final String id;
  String title;
  String categoryId;
  String memo;
  bool completed;
  DateTime? completedDate;
  String? photoPath;
  final DateTime createdAt;

  /// 「次に叶えたい」ピン留め。未達成リストの先頭に浮かせる優先フラグ。
  bool pinned;

  BucketItem({
    required this.id,
    required this.title,
    this.categoryId = 'other',
    this.memo = '',
    this.completed = false,
    this.completedDate,
    this.photoPath,
    required this.createdAt,
    this.pinned = false,
  });

  BucketCategory get category => BucketCategory.byId(categoryId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'memo': memo,
        'completed': completed,
        'completedDate': completedDate?.toIso8601String(),
        'photoPath': photoPath,
        'createdAt': createdAt.toIso8601String(),
        'pinned': pinned,
      };

  factory BucketItem.fromJson(Map<String, dynamic> json) => BucketItem(
        id: json['id'] as String,
        title: json['title'] as String,
        categoryId: json['categoryId'] as String? ?? 'other',
        memo: json['memo'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
        completedDate: json['completedDate'] != null
            ? DateTime.tryParse(json['completedDate'] as String)
            : null,
        photoPath: json['photoPath'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        pinned: json['pinned'] as bool? ?? false,
      );
}
