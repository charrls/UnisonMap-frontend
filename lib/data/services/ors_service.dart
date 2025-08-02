import 'package:dio/dio.dart';
import '../../models/ruta_ors_model.dart';

class ORSService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://unisonmap-fastapi.onrender.com/api', 
    connectTimeout: const Duration(seconds: 30), 
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<RutaORS?> obtenerRutaReal(int desdeId, int haciaId) async {
    try {
      print('Calculando ruta: $desdeId → $haciaId');
      
      final response = await _dio.get('/rutas/ors/$desdeId/$haciaId');
      
      if (response.statusCode == 200) {
        print('Ruta calculada exitosamente');
        print('Datos: ${response.data}');
        
        return RutaORS.fromJson(response.data);
      } else {
        print('Error HTTP: ${response.statusCode}');
        return null;
      }
      
    } on DioException catch (e) {
      print('Error de red al calcular ruta: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout) {
        print('Timeout de conexión');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        print('Timeout de recepción');
      } else if (e.type == DioExceptionType.connectionError) {
        print('Error de conexión - ¿Está el backend ejecutándose?');
      }
      
      return null;
    } catch (e) {
      print('Error inesperado al calcular ruta: $e');
      return null;
    }
  }

  Future<bool> verificarConexion() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
