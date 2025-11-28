import 'package:dio/dio.dart';
import '../../models/user_model.dart';

class AuthService {
  late final Dio _dio;
  
  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://unisonmap-fastapi.onrender.com/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  void setupInterceptor(Interceptor interceptor) {
    _dio.interceptors.clear();
    _dio.interceptors.add(interceptor);
  }

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

  Future<bool> validateToken(String token) async {
    try {
      print('Validando token...');
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      
      print('Token válido: ${response.statusCode == 200}');
      return response.statusCode == 200;
      
    } catch (e) {
      print('Token inválido o expirado: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          return false;
        }
        if (e.response == null) {
          print('Error de conexión - manteniendo sesión');
          return true;
        }
      }
      return false;
    }
  }

  Future<bool> isServerAvailable() async {
    try {
      await _dio.get('/health', options: Options(
        receiveTimeout: const Duration(seconds: 5),
      ));
      return true;
    } catch (e) {
      print('Servidor no disponible: $e');
      return false;
    }
  }
}