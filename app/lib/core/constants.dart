class AppConstants {
  // Use the active host machine's Wi-Fi IPv4 address so physical devices on the same network can connect.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://outfitted-production.up.railway.app',
  );

  // Freemium limits
  static const int freeTierWardrobeLimit = 20;
  static const int freeTierTryOnMonthlyLimit = 3;
}

