abstract class ApiConstants {
  // ── IMPORTANTE: En producción usar HTTPS — cambia http:// por https:// ──
  // iOS Simulator / Web:        'http://localhost:3000/api'
  // Android Emulator:           'http://10.0.2.2:3000/api'
  // Physical device (same LAN): 'http://192.168.x.x:3000/api'  ← your PC's IP
  // Producción:                 'https://tu-dominio.com/api'
  // ─────────────────────────────────────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.192:3000/api',
  );

  static const String login = '/auth/login';
  static const String setParentalPin = '/auth/parental';
  static const String disableParentalPin = '/auth/parental';
  static const String catalog = '/catalog';
  static const String channels = '/channels';
  static const String movies = '/movies';
  static const String series = '/series';
  static String stream(String id) => '/stream/$id';
  static String seriesEpisodes(String id) => '/series/$id/episodes';
  static const String epg = '/epg';
}

abstract class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String username = 'username';
  static const String serverUrl = 'server_url';
  static const String subscriptionType = 'subscription_type';
  static const String expiresAt = 'expires_at';
  static const String subscriptionExpired = 'subscription_expired';
  static const String favorites = 'favorites';
  static const String continueWatching = 'continue_watching';
  static const String hideAdultContent = 'hide_adult_content';
}

abstract class AppConstants {
  static const String appName = 'Connect World';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
