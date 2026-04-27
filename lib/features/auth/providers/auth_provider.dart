import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../../services/auth_service.dart';
import '../../../services/xtream_service.dart';
import '../../../models/user.dart';

// ── Demo mode flag ────────────────────────────────────────────────────────────
final demoModeProvider = StateProvider<bool>((ref) => false);

// ── Auth state: true when credentials are stored in Hive ─────────────────────
// NO observa authNotifierProvider para evitar que el router se recree
// durante loading/error y destruya el LoginScreen con sus campos.
final authStateProvider = StateProvider<bool>((ref) {
  return ref.read(localStorageProvider).isAuthenticated;
});

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> login(
      String serverUrl, String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      final user = await service.login(serverUrl, username, password);

      ref.read(demoModeProvider.notifier).state = false;
      ref.read(providerVersionProvider.notifier).state++;
      ref.read(authStateProvider.notifier).state = true;
      return user;
    });
  }

  Future<void> loginDemo() async {
    state = const AsyncLoading();
    ref.read(demoModeProvider.notifier).state = true;
    ref.read(providerVersionProvider.notifier).state++;
    ref.read(authStateProvider.notifier).state = true;
    state = const AsyncData(User(
      id: 'demo',
      username: 'Demo',
      token: '',
      subscriptionType: 'demo',
    ));
  }

  Future<void> logout() async {
    final isDemo = ref.read(demoModeProvider);
    if (!isDemo) {
      final service = ref.read(authServiceProvider);
      await service.logout();
    }
    ref.read(demoModeProvider.notifier).state = false;
    ref.read(providerVersionProvider.notifier).state++;
    ref.read(authStateProvider.notifier).state = false;
    state = const AsyncData(null);
  }
}
