import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';

class DioClient {
  static final DioClient _singleton = DioClient._internal();
  late final Dio dio;

  factory DioClient() {
    return _singleton;
  }

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Setup Bearer Auth interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Retrieve Firebase Auth token dynamically for secure API calls
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Centralized error logging
          print('Dio Client API Error [${e.response?.statusCode}]: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }
}
