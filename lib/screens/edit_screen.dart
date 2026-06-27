import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import '../models/bucket_item.dart';
import '../theme/app_theme.dart';
import '../utils/wish_examples.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key, this.item});

  /// null なら新規追加、ある場合は編集
  final BucketItem? item;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _memoCtrl;
  late String _categoryId;
  String? _photoPath;
  bool _saving = false;

  // 新規追加時に「やりたいこと」の例を動的に提示するための状態。
  late List<String> _examples; // シャッフル済みの例文
  int _hintIndex = 0; // いま表示中のヒント例文
  Timer? _hintTimer; // ヒントを自動で切り替えるタイマー
  bool _titleEmpty = true; // タイトルが空か（候補チップの表示判定）

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _memoCtrl = TextEditingController(text: item?.memo ?? '');
    _categoryId = item?.categoryId ?? 'other';
    _photoPath = item?.photoPath;
    _examples = shuffledExamples();
    _titleEmpty = _titleCtrl.text.trim().isEmpty;

    // 新規追加のときだけ、ヒント例文を一定間隔で切り替える。
    if (!_isEdit) {
      _titleCtrl.addListener(_onTitleChanged);
      _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || _titleCtrl.text.trim().isNotEmpty) return;
        setState(() => _hintIndex = (_hintIndex + 1) % _examples.length);
      });
    }
  }

  void _onTitleChanged() {
    final empty = _titleCtrl.text.trim().isEmpty;
    if (empty != _titleEmpty) {
      setState(() => _titleEmpty = empty);
    }
  }

  /// 候補をシャッフルし直して、別の顔ぶれを見せる。
  void _shuffleExamples() {
    setState(() {
      _examples = shuffledExamples();
      _hintIndex = 0;
    });
  }

  /// 候補チップをタップして、そのままタイトルに入れる。
  void _useExample(String text) {
    _titleCtrl.text = text;
    _titleCtrl.selection =
        TextSelection.collapsed(offset: text.length);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      // アプリ専用フォルダにコピーして永続化
      final dir = await bucketRepository.storage.photosDir();
      final ext = picked.path.split('.').last;
      final dest = '${dir.path}/${const Uuid().v4()}.$ext';
      await File(picked.path).copy(dest);
      setState(() => _photoPath = dest);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真を読み込めませんでした')),
        );
      }
    }
  }

  void _showPhotoOptions() {
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
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.accent),
              title: const Text('ライブラリから選択'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('写真を削除'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final title = _titleCtrl.text.trim();
    final memo = _memoCtrl.text.trim();

    if (_isEdit) {
      final item = widget.item!;
      item
        ..title = title
        ..memo = memo
        ..categoryId = _categoryId
        ..photoPath = _photoPath;
      await bucketRepository.update(item);
    } else {
      await bucketRepository.add(
        BucketItem(
          id: const Uuid().v4(),
          title: title,
          memo: memo,
          categoryId: _categoryId,
          photoPath: _photoPath,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '編集' : 'やりたいことを追加'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _Label('やりたいこと'),
              TextFormField(
                controller: _titleCtrl,
                maxLines: 2,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: '例：${_examples[_hintIndex]}',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '内容を入力してください' : null,
              ),
              if (!_isEdit && _titleEmpty)
                _ExampleSuggestions(
                  examples: _examples.take(6).toList(),
                  onPick: _useExample,
                  onShuffle: _shuffleExamples,
                ),
              const SizedBox(height: 20),
              const _Label('カテゴリ'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in BucketCategory.all)
                    GestureDetector(
                      onTap: () => setState(() => _categoryId = c.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _categoryId == c.id ? c.color : AppTheme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _categoryId == c.id
                                ? c.color
                                : AppTheme.border,
                          ),
                        ),
                        child: Text(
                          '${c.emoji} ${c.label}',
                          style: TextStyle(
                            color: _categoryId == c.id
                                ? Colors.white
                                : AppTheme.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const _Label('メモ・想い（任意）'),
              TextFormField(
                controller: _memoCtrl,
                maxLines: 4,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: 'なぜやりたい？どんな気持ち？自由に書こう',
                ),
              ),
              const SizedBox(height: 20),
              const _Label('写真（任意）'),
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _photoPath != null && File(_photoPath!).existsSync()
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(_photoPath!), fit: BoxFit.cover),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 18,
                                child: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white, size: 18),
                                  onPressed: _showPhotoOptions,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 36,
                                color: AppTheme.ink.withValues(alpha: 0.4)),
                            const SizedBox(height: 8),
                            Text('タップして写真を追加',
                                style: TextStyle(
                                    color:
                                        AppTheme.ink.withValues(alpha: 0.5))),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEdit ? '保存する' : '追加する',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppTheme.ink,
        ),
      ),
    );
  }
}

/// やりたいことの候補をチップで提示し、タップでそのまま入力できるブロック。
/// 「言われてみればやりたかった」を思い出すきっかけにする。
class _ExampleSuggestions extends StatelessWidget {
  const _ExampleSuggestions({
    required this.examples,
    required this.onPick,
    required this.onShuffle,
  });

  final List<String> examples;
  final ValueChanged<String> onPick;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                '思いつかない？タップで入れてみよう',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onShuffle,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 2),
                    Text(
                      '他の例',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in examples)
                GestureDetector(
                  onTap: () => onPick(example),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      example,
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
      ),
    );
  }
}
