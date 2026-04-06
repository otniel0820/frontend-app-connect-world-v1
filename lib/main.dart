import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('auth');
  await Hive.openBox('favorites');
  await Hive.openBox('continue_watching');
  await Hive.openBox('series_progress');
  runApp(
    const ProviderScope(
      child: ConnectWorldApp(),
    ),
  );
}

class ConnectWorldApp extends ConsumerWidget {
  const ConnectWorldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Connect World',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
