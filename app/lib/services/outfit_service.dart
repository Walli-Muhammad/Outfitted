import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/outfit_response.dart';

class OutfitService {
  final Dio _dio = DioClient().dio;

  /// Calls POST /outfits/suggest and returns a parsed [OutfitResponse].
  /// Throws [DioException] on network/server errors so the provider can catch and display a SnackBar.
  Future<OutfitResponse> getSuggestions({
    required String userId,
    required String occasion,
    required String city,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/outfits/suggest',
      data: {
        'user_id': userId,
        'occasion': occasion,
        'city': city,
      },
    );

    if (response.data == null) {
      throw Exception('Empty response from /outfits/suggest');
    }

    return OutfitResponse.fromJson(response.data!);
  }
}
