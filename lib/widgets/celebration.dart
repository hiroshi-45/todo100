import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 節目（マイルストーン）になる達成数。これらの倍数で特別演出を出す。
const int _milestoneStep = 5;

/// 区切りのよい数字に対する特別メッセージ
const Map<int, String> _specialMessages = {
  5: '5個達成！\n順調なスタートだね🎉',
  10: '10個達成！\nふた桁に突入🎊',
  25: '25個達成！\n全体の 1/4 をクリア🌟',
  50: '50個達成！\nついに折り返し地点🏁',
  75: '75個達成！\nゴールが見えてきた🔥',
  100: '100個コンプリート！！\n本当におめでとう🏆',
};

/// ふつうの達成時に出すひとことメッセージ
const List<String> _smallMessages = [
  'やったね！🎉',
  'ナイス！✨',
  'また一つ叶えたね😊',
  'その調子！🙌',
  '一歩前進！👏',
];

/// 達成演出の内容（節目かどうか・表示メッセージ）。
class CelebrationInfo {
  const CelebrationInfo({required this.isMilestone, required this.message});
  final bool isMilestone;
  final String message;
}

/// 達成数 [completedCount] から、どんな演出を出すかを決める純粋関数。
///
/// - 節目（[_milestoneStep] の倍数）：特別な祝福メッセージ
/// - それ以外：ランダムなひとことメッセージ
CelebrationInfo celebrationInfo(int completedCount, {Random? random}) {
  final isMilestone =
      completedCount > 0 && completedCount % _milestoneStep == 0;
  if (isMilestone) {
    final message = _specialMessages[completedCount] ??
        '$completedCount個達成！\nその調子で進もう🎉';
    return CelebrationInfo(isMilestone: true, message: message);
  }
  final r = random ?? Random();
  return CelebrationInfo(
    isMilestone: false,
    message: _smallMessages[r.nextInt(_smallMessages.length)],
  );
}

/// 達成数 [completedCount] に応じた達成演出を表示する。
///
/// - 節目（5の倍数）：紙吹雪たっぷりの「マイルストーン祝福」（手動で閉じる）
/// - それ以外：紙吹雪と短いメッセージのトースト（自動で消える）
Future<void> showCelebration(
  BuildContext context, {
  required int completedCount,
}) async {
  final info = celebrationInfo(completedCount);
  if (info.isMilestone) {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _MilestoneDialog(
        count: completedCount,
        message: info.message,
      ),
    );
  } else {
    await _showToast(context, info.message);
  }
}

// テーマ（[AppTheme]）の現在の配色に追従するため、コンパイル時定数にはしない。
List<Color> get _confettiColors => [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
      AppTheme.orange,
      Colors.white,
    ];

/// 自動で消える小さな達成トースト
Future<void> _showToast(BuildContext context, String message) async {
  final overlay = Overlay.of(context);
  final controller =
      ConfettiController(duration: const Duration(milliseconds: 600));
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: controller,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.08,
                numberOfParticles: 16,
                maxBlastForce: 18,
                minBlastForce: 6,
                gravity: 0.25,
                colors: _confettiColors,
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.55),
              child: _ToastCard(message: message),
            ),
          ],
        ),
      ),
    ),
  );

  overlay.insert(entry);
  controller.play();
  await Future.delayed(const Duration(milliseconds: 1700));
  entry.remove();
  controller.dispose();
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({required this.message});
  final String message;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _ac, curve: Curves.elasticOut);
    return ScaleTransition(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          widget.message,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
      ),
    );
  }
}

/// 節目の達成を祝う大きめのダイアログ
class _MilestoneDialog extends StatefulWidget {
  const _MilestoneDialog({required this.count, required this.message});
  final int count;
  final String message;

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 3));
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 上中央から降りそそぐ紙吹雪
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 24,
            maxBlastForce: 24,
            minBlastForce: 8,
            gravity: 0.22,
            colors: _confettiColors,
          ),
        ),
        ScaleTransition(
          scale: CurvedAnimation(parent: _ac, curve: Curves.elasticOut),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [AppTheme.secondary, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  const Text(
                    'おめでとう！',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'つづける',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
