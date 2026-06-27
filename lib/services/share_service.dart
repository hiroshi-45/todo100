import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// ウィジェットを画像化して共有するサービス。
///
/// [RepaintBoundary] でラップした表示中ウィジェットを PNG にして、
/// OS の共有シートに渡す。
class ShareService {
  /// [boundaryKey] が指す [RepaintBoundary] を画像化し、共有シートを開く。
  ///
  /// 画像化に失敗した場合は false を返す（呼び出し側で通知する）。
  Future<bool> shareBoundary(
    GlobalKey boundaryKey, {
    String? text,
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return false;

    // 高解像度（SNS映え）でキャプチャ。
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return false;

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/yumetsumi_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
    return true;
  }
}

/// アプリ共有で使う [ShareService] の共有インスタンス。
final shareService = ShareService();
