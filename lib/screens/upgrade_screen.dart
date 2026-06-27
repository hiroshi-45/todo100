import 'package:flutter/material.dart';

import '../main.dart';
import '../repository/premium_repository.dart';
import '../theme/app_theme.dart';

/// プレミアム（買い切り）の案内・購入画面。
///
/// 無料の上限に達したとき、またはドロワーの「プレミアム」から開かれる。
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _wasPremium = false;

  @override
  void initState() {
    super.initState();
    _wasPremium = premiumRepository.isPremium;
    premiumRepository.addListener(_onPremiumChanged);
  }

  void _onPremiumChanged() {
    // 購入・復元が成立した瞬間にお礼を出す。
    if (!_wasPremium && premiumRepository.isPremium && mounted) {
      _wasPremium = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ありがとう！さあ、100個ぜんぶ叶えにいこう🎉')),
      );
    }
  }

  @override
  void dispose() {
    premiumRepository.removeListener(_onPremiumChanged);
    super.dispose();
  }

  Future<void> _buy() async {
    if (!premiumRepository.storeAvailable || !premiumRepository.productReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('いまストアに接続できません。少し時間をおいて試してください')),
      );
      return;
    }
    await premiumRepository.buy();
  }

  Future<void> _restore() async {
    await premiumRepository.restore();
    if (!mounted) return;
    if (!premiumRepository.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('復元できる購入が見つかりませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.ink,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: premiumRepository,
          builder: (context, _) {
            return premiumRepository.isPremium
                ? _thankYou(context)
                : _offer(context);
          },
        ),
      ),
    );
  }

  /// 購入前の案内（オファー）。
  Widget _offer(BuildContext context) {
    final pending = premiumRepository.purchasePending;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text('✨', style: TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'ユメツミ プレミアム',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '夢は、まだまだ積める。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEE2D8)),
          ),
          child: const Column(
            children: [
              _Benefit(
                emoji: '💯',
                title: 'やりたいことを100個まで登録',
                subtitle: '無料プランは$kFreeItemLimit個まで。続きはプレミアムで。',
              ),
              _Benefit(
                emoji: '🖼️',
                title: 'シェア画像の書き出し',
                subtitle: '叶えた瞬間を、SNS映えするカードにして共有。',
              ),
              _Benefit(
                emoji: '🎨',
                title: 'テーマの着せ替え',
                subtitle: '5種類の配色から、自分らしい見た目に。',
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: pending ? null : _buy,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: pending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'プレミアムにする（${premiumRepository.priceLabel} 買い切り）',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '一度のお支払いで、追加課金はありません',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.ink.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: pending ? null : _restore,
            child: const Text('購入を復元する'),
          ),
        ),
      ],
    );
  }

  /// 購入後（または復元後）のお礼状態。
  Widget _thankYou(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(
            'プレミアム会員です',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'さあ、100個ぜんぶ叶えにいこう。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'リストに戻る',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.last = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
