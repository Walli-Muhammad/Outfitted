import 'package:dio/dio.dart';
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
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Setup Auth interceptor with hardcoded dev-user-1
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['x-user-id'] = 'dev-user-1';
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

