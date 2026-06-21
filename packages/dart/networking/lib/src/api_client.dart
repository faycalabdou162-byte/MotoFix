import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;

  Future<Response<dynamic>> get(String path) => _dio.get(path);
}
