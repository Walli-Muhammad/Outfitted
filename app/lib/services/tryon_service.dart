import 'dart:io';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/tryon_result.dart';

class TryOnService {
  final Dio _dio = DioClient().dio;

  /// Uploads a full-body model photo via multipart POST to /tryon/model-photo.
  /// Returns the Cloudinary URL of the uploaded photo.
  Future<String> uploadModelPhoto(File photo, String userId) async {
    final fileName = photo.path.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'user_id': userId,
      'file': await MultipartFile.fromFile(photo.path, filename: fileName),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/tryon/model-photo',
      data: formData,
    );

    if (response.data == null) throw Exception('Empty response from /tryon/model-photo');
    return response.data!['model_photo_url'] as String;
  }

  /// Calls POST /tryon/generate and returns a [TryOnResult].
  /// Can take 15–30 seconds while Replicate processes the image.
  Future<TryOnResult> generateTryOn(String userId, String itemId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/tryon/generate',
      data: {'user_id': userId, 'item_id': itemId},
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );

    if (response.data == null) throw Exception('Empty response from /tryon/generate');
    return TryOnResult.fromJson(response.data!);
  }

  /// Fetches all try-on history for a user from GET /tryon/history/{userId}.
  Future<List<TryOnResult>> getHistory(String userId) async {
    final response = await _dio.get<List<dynamic>>('/tryon/history/$userId');
    final list = response.data ?? [];
    return list
        .map((e) => TryOnResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a single try-on result via DELETE /tryon/history/{resultId}.
  Future<void> deleteTryOn(String resultId) async {
    await _dio.delete('/tryon/history/$resultId');
  }
}
