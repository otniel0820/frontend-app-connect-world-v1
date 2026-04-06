import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';

// Solo cambia cuando el token en storage cambia (login exitoso o logout).
// NO observa authNotifierProvider para evitar que el router se recree
// durante loading/error y destruya el LoginScreen con sus campos.
final authStateProvider = StateProvider<bool>((ref) {
  return ref.read(localStorageProvider).isAuthenticated;
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      final user = await service.login(username, password);
      // Notificar al router solo cuando el login es exitoso
      ref.read(authStateProvider.notifier).state = true;
      return user;
    });
  }

  Future<void> logout() async {
    final service = ref.read(authServiceProvider);
    await service.logout();
    ref.read(authStateProvider.notifier).state = false;
    state = const AsyncData(null);
  }
}
