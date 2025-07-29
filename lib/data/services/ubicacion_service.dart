/// ubicacion_service.dart
import 'package:dio/dio.dart';
import '../../models/ubicacion_model.dart';

class UbicacionService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://unisonmap-fastapi.onrender.com/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));


  Future<List<UbicacionModel>> fetchUbicaciones() async {
    try {
      print('Obteniendo ubicaciones del backend...');
      final response = await _dio.get('/ubicaciones');
      
      if (response.statusCode == 200) {
        final List data = response.data;
        print('Respuesta exitosa del backend');
        print('Total de ubicaciones recibidas: ${data.length}');
        print('Primeras 3 ubicaciones: ${data.take(3)}');
        
        final ubicaciones = data.map((e) => UbicacionModel.fromJson(e)).toList();
        print('${ubicaciones.length} ubicaciones procesadas correctamente');
        
        return ubicaciones;
      } else {
        print('Error HTTP: ${response.statusCode}');
        return [];
      }

    } on DioException catch (e) {
      print('Error de red al obtener ubicaciones: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout) {
        print('Timeout de conexión');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        print('Timeout de recepción');
      } else if (e.type == DioExceptionType.connectionError) {
        print('Error de conexión - ¿Está el backend ejecutándose?');
      }
      
      return [];
    } catch (e) {
      print('Error inesperado al obtener ubicaciones: $e');
      return [];
    }
  }
}
