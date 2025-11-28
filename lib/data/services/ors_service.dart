import 'package:dio/dio.dart';

import '../../core/enums/ors_profile.dart';
import '../../models/ruta_ors_model.dart';

class RouteRequestException implements Exception {
  RouteRequestException(
    this.message, {
    this.allowedProfiles,
    this.allowedProfileLabels,
  });

  final String message;
  final List<String>? allowedProfiles;
  final List<String>? allowedProfileLabels;
}

class ORSService {
  ORSService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://unisonmap-fastapi.onrender.com/api',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: const <String, dynamic>{
                  'Content-Type': 'application/json',
                },
              ),
            );

  final Dio _dio;

  Future<RutaORSResponse?> obtenerRutaReal({
    required int desdeId,
    required int haciaId,
    OrsProfile? profile,
  }) async {
    try {
      final profileLabel = profile?.apiValue ?? '(por defecto)';
      print('Calculando ruta por IDs: $desdeId → $haciaId con perfil $profileLabel');

      final queryParameters = <String, dynamic>{};
      if (profile != null) {
        queryParameters['profile'] = profile.apiValue;
      }

      final response = await _dio.get(
        '/rutas/ors/$desdeId/$haciaId',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      if (response.statusCode == 200) {
        print('Ruta calculada exitosamente');
        print('Datos: ${response.data}');

  return RutaORSResponse.fromJson(response.data as Map<String, dynamic>);
      }

      print('Error HTTP: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      print('Error de red al calcular ruta: ${e.message}');

      final invalidProfileException = _mapInvalidProfileException(e);
      if (invalidProfileException != null) {
        throw invalidProfileException;
      }

      final status = e.response?.statusCode;
      if (status == 400) {
        throw RouteRequestException('No se pudo calcular la ruta con los datos proporcionados.');
      }
      if (status == 502) {
        throw RouteRequestException('El servicio de rutas no está disponible en este momento.');
      }

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

  Future<RutaORSResponse?> obtenerRutaPorCoordenadas({
    required double origenLat,
    required double origenLng,
    required double destinoLat,
    required double destinoLng,
    OrsProfile? profile,
  }) async {
    try {
      final profileLabel = profile?.apiValue ?? '(por defecto)';
      print('Calculando ruta por coordenadas con perfil $profileLabel');

      final payload = <String, dynamic>{
        'origin': <double>[origenLng, origenLat],
        'destination': <double>[destinoLng, destinoLat],
      };

      if (profile != null) {
        payload['profile'] = profile.apiValue;
      }

      final response = await _dio.post(
        '/rutas/ors/coordenadas',
        data: payload,
      );

      if (response.statusCode == 200) {
  return RutaORSResponse.fromJson(response.data as Map<String, dynamic>);
      }

      print('Error HTTP al calcular ruta con coordenadas: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      print('Error de red al calcular ruta con coordenadas: ${e.message}');

      final invalidProfileException = _mapInvalidProfileException(e);
      if (invalidProfileException != null) {
        throw invalidProfileException;
      }

      final status = e.response?.statusCode;
      if (status == 400) {
        throw RouteRequestException('Verifica los datos de origen y destino e inténtalo de nuevo.');
      }
      if (status == 502) {
        throw RouteRequestException('No se pudo contactar al servicio de rutas. Intenta más tarde.');
      }

      return null;
    } catch (e) {
      print('Error inesperado al calcular ruta con coordenadas: $e');
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

  RouteRequestException? _mapInvalidProfileException(DioException error) {
    final response = error.response;
    if (response?.statusCode != 400) {
      return null;
    }

    final dynamic data = response?.data;
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final dynamic detail = data['detail'];
    if (detail is! Map<String, dynamic>) {
      return null;
    }

    if (detail['code'] != 'invalid_profile') {
      return null;
    }

  final Iterable<dynamic> allowedRaw = detail['allowed'] is Iterable<dynamic>
    ? (detail['allowed'] as Iterable<dynamic>)
    : const <dynamic>[];
  final List<String> allowedLabels = mapAllowedProfileLabels(allowedRaw);

  final List<String> allowedApiValues = allowedRaw
    .map((dynamic value) => value == null ? '' : value.toString())
    .where((String value) => value.isNotEmpty)
    .toList();

  final List<String> fallbackApiValues = allowedApiValues.isNotEmpty
    ? allowedApiValues
    : kDefaultOrsProfiles.map((OrsProfile profile) => profile.apiValue).toList();

  final List<String> fallbackLabels = allowedLabels.isNotEmpty
    ? allowedLabels
    : kDefaultOrsProfiles.map((OrsProfile profile) => profile.label).toList();

  final String apiMessage = fallbackApiValues.join(', ');
  final String labelMessage = fallbackLabels.join(', ');

    final StringBuffer buffer = StringBuffer('El perfil seleccionado no es válido.');
    final String? received = detail['received']?.toString();
    if (received != null && received.isNotEmpty) {
      buffer.write(' (Recibido: $received)');
    }
    if (apiMessage.isNotEmpty) {
      buffer.write(' Perfiles permitidos: $apiMessage');
      if (labelMessage.isNotEmpty && labelMessage != apiMessage) {
        buffer.write(' ($labelMessage)');
      }
      buffer.write('.');
    }

    return RouteRequestException(
      buffer.toString(),
      allowedProfiles: fallbackApiValues,
      allowedProfileLabels: fallbackLabels,
    );
  }
}
