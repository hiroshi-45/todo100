import 'package:flutter/material.dart';

import 'repository/bucket_repository.dart';
import 'repository/premium_repository.dart';
import 'repository/profile_repository.dart';
import 'repository/theme_repository.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

/// アプリ全体で共有するリポジトリ
final _storage = StorageService();
final bucketRepository = BucketRepository(_storage);
final profileRepository = ProfileRepository(_storage);
final premiumRepository = PremiumRepository(_storage);
final themeRepository = ThemeRepository(_storage, premiumRepository);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // テーマはプレミアム権利を見て決めるので、先に課金状態を確定させる。
  await premiumRepository.init();
  await Future.wait([
    bucketRepository.init(),
    profileRepository.init(),
    themeRepository.init(),
  ]);
  runApp(const Zom100App());
}

class Zom100App extends StatelessWidget {
  const Zom100App({super.key});

  @override
  Widget build(BuildContext context) {
    // テーマ変更で配色一式を反映するため、MaterialAppごと再構築する。
    return ListenableBuilder(
      listenable: themeRepository,
      builder: (context, _) => MaterialApp(
        title: '死ぬまでにやりたい100のこと',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
  }
}
