import 'package:dio/dio.dart';
import '../../models/user_model.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://unisonmap-fastapi.onrender.com/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<String?> login(String email, String password) async {
    try {
      print('Intentando login en: ${_dio.options.baseUrl}/auth/login');
      
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
      
      print('Login exitoso: ${response.data}');
      return response.data['access_token'];
      
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      print('Intentando registro en: ${_dio.options.baseUrl}/usuarios/register');
      
      await _dio.post('/usuarios/register', data: userData);
      print('Registro exitoso');
      return true;
      
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<UserModel?> getCurrentUser(String token) async {
    try {
      print('Obteniendo usuario con token: ${token.substring(0, 20)}...');
      print('URL: ${_dio.options.baseUrl}/auth/me');
      
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      
      print('Usuario obtenido exitosamente: ${response.data}');
      return UserModel.fromJson(response.data);
      
    } catch (e) {
      print('Error al obtener el usuario: $e');
      if (e is DioException && e.response?.statusCode == 404) {
        print('Endpoint /auth/me no encontrado - verificar backend');
      }
      return null;
    }
  }
}