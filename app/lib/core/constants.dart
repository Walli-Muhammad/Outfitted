class AppConstants {
  // Use the active host machine's Wi-Fi IPv4 address so physical devices on the same network can connect.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.18.70:8000',
  );

  // Freemium limits
  static const int freeTierWardrobeLimit = 20;
  static const int freeTierTryOnMonthlyLimit = 3;
}

