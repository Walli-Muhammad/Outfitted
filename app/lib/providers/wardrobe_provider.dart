import 'dart:io';
import 'package:flutter/material.dart';
import '../core/dio_client.dart';
import '../models/wardrobe_item.dart';
import '../services/wardrobe_service.dart';

class WardrobeProvider with ChangeNotifier {
  final WardrobeService _service = WardrobeService();

  List<WardrobeItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WardrobeItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Retrieve user items from database
  Future<void> loadItems(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _service.fetchItems(userId);
    } catch (e) {
      _errorMessage = 'Could not load your wardrobe. Please check connection.';
      print('Load Items Provider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload new garment and insert it directly into list on success
  Future<WardrobeItem?> addItem(File imageFile, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newItem = await _service.uploadItem(imageFile, userId);
      // Smoothly insert at the beginning of the grid without full reload
      _items.insert(0, newItem);
      notifyListeners();
      return newItem;
    } catch (e) {
      _errorMessage = 'AI tagging failed. Please try again.';
      print('Add Item Provider Error: $e');
      rethrow; // Rethrow to let the UI display a custom SnackBar
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear any existing error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update an item's tags
  Future<void> updateItem(String itemId, Map<String, dynamic> updateData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedItem = await _service.updateItem(itemId, updateData);
      // Replace the old item with the updated item
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }
    } catch (e) {
      _errorMessage = 'Failed to update item details.';
      print('Update Item Provider Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a wardrobe item
  Future<void> deleteItem(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await DioClient().dio.delete('/wardrobe/items/$itemId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _items.removeWhere((item) => item.id == itemId);
      } else {
        throw Exception('Failed to delete item');
      }
    } catch (e) {
      _errorMessage = 'Failed to delete item.';
      print('Delete Item Provider Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
