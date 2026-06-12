import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tryon_result.dart';
import '../services/tryon_service.dart';

class TryOnProvider with ChangeNotifier {
  final TryOnService _service = TryOnService();

  // Premium gate — hardcoded true for now; wire to RevenueCat later
  final bool isPremium = true;

  List<TryOnResult> history = [];
  bool isGenerating = false;
  bool isUploadingPhoto = false;
  bool isLoadingHistory = false;
  String? modelPhotoUrl;
  String? errorMessage;

  // ── Model Photo ────────────────────────────────────────────────────────────

  Future<void> uploadModelPhoto(File photo, String userId) async {
    isUploadingPhoto = true;
    errorMessage = null;
    notifyListeners();

    try {
      modelPhotoUrl = await _service.uploadModelPhoto(photo, userId);
    } catch (e) {
      errorMessage = 'Could not upload model photo. Please try again.';
      debugPrint('TryOnProvider.uploadModelPhoto error: $e');
    } finally {
      isUploadingPhoto = false;
      notifyListeners();
    }
  }

  // ── Try-On Generation ──────────────────────────────────────────────────────

  Future<void> generateTryOn(String userId, String itemId) async {
    isGenerating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.generateTryOn(userId, itemId);
      // Prepend so newest result is first
      history.insert(0, result);
    } catch (e) {
      errorMessage = 'Try-on failed. Please check your model photo and try again.';
      debugPrint('TryOnProvider.generateTryOn error: $e');
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  // ── History ────────────────────────────────────────────────────────────────

  Future<void> loadHistory(String userId) async {
    isLoadingHistory = true;
    notifyListeners();

    try {
      final data = await _service.getHistory(userId);
      history = data['history'] as List<TryOnResult>;
      modelPhotoUrl = data['model_photo_url'] as String?;
    } catch (e) {
      debugPrint('TryOnProvider.loadHistory error: $e');
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteTryOn(String resultId) async {
    try {
      await _service.deleteTryOn(resultId);
      history.removeWhere((r) => r.id == resultId);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Could not delete try-on result. Please try again.';
      debugPrint('TryOnProvider.deleteTryOn error: $e');
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
