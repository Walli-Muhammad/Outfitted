import 'package:flutter/material.dart';
import '../models/outfit_response.dart';
import '../services/outfit_service.dart';

class OutfitProvider with ChangeNotifier {
  final OutfitService _service = OutfitService();

  OutfitResponse? currentSuggestions;
  bool isLoading = false;
  String? errorMessage;

  /// Fetches AI outfit suggestions and notifies listeners.
  Future<void> loadSuggestions({
    required String userId,
    required String occasion,
    required String city,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentSuggestions = await _service.getSuggestions(
        userId: userId,
        occasion: occasion,
        city: city,
      );
    } catch (e) {
      errorMessage = 'Could not load outfit suggestions. Please try again.';
      debugPrint('OutfitProvider error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
