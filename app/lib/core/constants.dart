class AppConstants {
  // Use 10.0.2.2 to point to host localhost when running on Android emulator,
  // otherwise fallback to localhost for iOS simulator or web.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Freemium limits
  static const int freeTierWardrobeLimit = 20;
  static const int freeTierTryOnMonthlyLimit = 3;
}
