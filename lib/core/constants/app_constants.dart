abstract class StorageKeys {
  // Xtream credentials
  static const String xtreamUrl = 'xtream_url';
  static const String xtreamUsername = 'xtream_username';
  static const String xtreamPassword = 'xtream_password';

  // User profile (cached from Xtream auth)
  static const String username = 'username';
  static const String subscriptionType = 'subscription_type';
  static const String expiresAt = 'expires_at';

  // Local user data
  static const String favorites = 'favorites';
  static const String continueWatching = 'continue_watching';
  static const String hideAdultContent = 'hide_adult_content';
  static const String parentalPin = 'parental_pin';
}

abstract class AppConstants {
  static const String appName = 'Connect World';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  // Number of items shown per content row in the home screen
  static const int homeRowLimit = 20;
  // Client-side page size for movies/series screens
  static const int catalogPageSize = 100;
}
