import 'dart:io';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/wardrobe_item.dart';

class WardrobeService {
  final Dio _dio = DioClient().dio;

  // Retrieves all wardrobe items for a specific user, ordered by created_at descending
  Future<List<WardrobeItem>> fetchItems(String userId) async {
    try {
      final response = await _dio.get('/wardrobe/items/$userId');
      if (response.statusCode == 200) {
        final list = response.data as List? ?? [];
        return list.map((item) => WardrobeItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load wardrobe items');
    } catch (e) {
      print('Fetch Wardrobe Items Error: $e');
      rethrow;
    }
  }

  // Uploads a garment image and tags it via AI auto-tagging
  Future<WardrobeItem> uploadItem(File imageFile, String userId) async {
    try {
      final String fileName = imageFile.path.split('/').last;
      
      // Multipart/form-data payload with user_id and file
      final FormData formData = FormData.fromMap({
        'user_id': userId,
        'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      final response = await _dio.post('/wardrobe/items', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return WardrobeItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to upload wardrobe item');
    } catch (e) {
      print('Upload Wardrobe Item Error: $e');
      rethrow;
    }
  }

  // Updates an existing wardrobe item's tags (type, color, style)
  Future<WardrobeItem> updateItem(String itemId, Map<String, dynamic> updateData) async {
    try {
      final response = await _dio.patch('/wardrobe/items/$itemId', data: updateData);
      if (response.statusCode == 200) {
        return WardrobeItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update wardrobe item');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to update wardrobe item');
    } catch (e) {
      print('Update Wardrobe Item Error: $e');
      rethrow;
    }
  }
}
