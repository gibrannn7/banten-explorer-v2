import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.4:8000',    
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  Future<Map<String, dynamic>> sendMessage(String message, String language) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {'query': message, 'language': language},
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

  Future<Map<String, dynamic>> sendAudioMessage(String filePath, String language) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'audio.m4a'),
        'language': language,
      });

      final response = await _dio.post(
        '/chat/audio',
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return {
        "user_text": "Gagal terhubung",
        "bot_response": {
          "pesan": "Gagal terhubung ke server. Detail: ${e.message}",
          "tampilkan_map": false,
          "keyword_lokasi": null,
          "gambar_urls": []
        }
      };
    } catch (e) {
      return {
        "user_text": "Error",
        "bot_response": {
          "pesan": "Terjadi kesalahan internal. Detail: ${e.toString()}",
          "tampilkan_map": false,
          "keyword_lokasi": null,
          "gambar_urls": []
        }
      };
    }
  }
}