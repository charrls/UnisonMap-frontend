/// auth_service.dart
import 'package:dio/dio.dart';
import '../../models/user_model.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8000/api'));

  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      return response.data['access_token'];
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      await _dio.post('/usuarios/register', data: userData);
      return true;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<UserModel?> getCurrentUser(String token) async {
  try {
    final response = await _dio.get(
      '/auth/me',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
      }),
    );
    print('Usuario obtenido: ${response.data}');
    return UserModel.fromJson(response.data);
  } catch (e) {
    print('Error al obtener el usuario: $e');
    return null;
  }
}

}

