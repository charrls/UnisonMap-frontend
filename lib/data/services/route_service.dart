import 'package:dio/dio.dart';
import '../../models/route_model.dart';

class RouteService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8000/api'));

  Future<RouteModel?> calcularRuta(int desdeId, int haciaId) async {
    try {
      final response = await _dio.get('/rutas/$desdeId/$haciaId');
      return RouteModel.fromJson(response.data);
    } catch (e) {
      print('Error calculando ruta: $e');
      return null;
    }
  }
}