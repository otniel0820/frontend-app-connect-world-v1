import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Manejador global de errores de UI: en vez de una pantalla gris/blanca muda
  // (comportamiento por defecto en release), mostramos el motivo real del fallo.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0D0D0D),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFE53935), size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Ocurrió un error en pantalla',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };
  // Permitimos vertical y horizontal: el menú se adapta a ambas. El reproductor
  // fuerza horizontal por su cuenta al reproducir y restaura todas al salir.
  // En TV siempre es horizontal, así que esto no le afecta.
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
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
      // Layout fijo estilo TV: ignoramos el tamaño de fuente del sistema para
      // que las letras no se desborden en teléfonos con fuente grande.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.0),
        ),
        child: child!,
      ),
    );
  }
}
