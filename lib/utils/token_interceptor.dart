import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';

class TokenInterceptor extends Interceptor {
  final AuthProvider authProvider;

  TokenInterceptor(this.authProvider);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      print('Token expirado detectado - cerrando sesión automáticamente');
      
      authProvider.logout();
      
    }
    
    handler.next(err);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = authProvider.token;
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
}
