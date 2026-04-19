import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.9:8000',    
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {'query': message},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return {
        "pesan": "Gagal terhubung ke server. Pastikan perangkat dan server berada di jaringan yang sama. Detail: ${e.message}",
        "tampilkan_map": false,
        "keyword_lokasi": null
      };
    } catch (e) {
      return {
        "pesan": "Terjadi kesalahan internal pada aplikasi. Detail: ${e.toString()}",
        "tampilkan_map": false,
        "keyword_lokasi": null
      };
    }
  }
}