import 'package:latlong2/latlong.dart';

import '../core/enums/ors_profile.dart';

class RutaUbicacion {
  const RutaUbicacion({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory RutaUbicacion.fromJson(Map<String, dynamic> json) {
    return RutaUbicacion(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lat': lat,
        'lng': lng,
      };

  LatLng toLatLng() => LatLng(lat, lng);
}

class RutaStep {
  const RutaStep({
    required this.orden,
    required this.texto,
    required this.distanceM,
    required this.durationS,
    this.location,
  });

  final int orden;
  final String texto;
  final int distanceM;
  final int durationS;
  final RutaUbicacion? location;

  factory RutaStep.fromJson(Map<String, dynamic> json) {
    return RutaStep(
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      texto: (json['texto'] ?? '').toString(),
      distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
      durationS: (json['duration_s'] as num?)?.toInt() ?? 0,
      location: json['location'] is Map<String, dynamic>
          ? RutaUbicacion.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'orden': orden,
        'texto': texto,
        'distance_m': distanceM,
        'duration_s': durationS,
        if (location != null) 'location': location!.toJson(),
      };

  double get distanceKm => distanceM / 1000.0;
  double get durationMinutes => durationS / 60.0;

  factory RutaStep.manual({
    required int orden,
    required String texto,
    int distanceM = 0,
    int durationS = 0,
    RutaUbicacion? location,
  }) {
    return RutaStep(
      orden: orden,
      texto: texto,
      distanceM: distanceM,
      durationS: durationS,
      location: location,
    );
  }
}

class RutaORSResponse {
  RutaORSResponse({
    required this.ruta,
    required this.distanciaM,
    required this.duracionS,
    required this.instrucciones,
    required this.stepsCount,
    required this.currentStepIndex,
    this.profile,
    this.origen,
    this.destino,
  });

  final List<LatLng> ruta;
  final int distanciaM;
  final int duracionS;
  final List<RutaStep> instrucciones;
  final int stepsCount;
  final int currentStepIndex;
  final OrsProfile? profile;
  final RutaUbicacion? origen;
  final RutaUbicacion? destino;

  factory RutaORSResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawRuta = json['ruta'] as List<dynamic>? ?? const <dynamic>[];
    final List<LatLng> puntos = rawRuta.map((dynamic punto) {
      if (punto is List && punto.length >= 2) {
        final double lon = (punto[0] as num).toDouble();
        final double lat = (punto[1] as num).toDouble();
        return LatLng(lat, lon);
      }
      if (punto is Map<String, dynamic>) {
        final double lat = (punto['lat'] as num).toDouble();
        final double lng = (punto['lng'] as num).toDouble();
        return LatLng(lat, lng);
      }
      throw ArgumentError('Formato de coordenadas no soportado: $punto');
    }).toList();

    final List<dynamic> rawInstrucciones = json['instrucciones'] as List<dynamic>? ?? const <dynamic>[];
    final List<RutaStep> instrucciones = rawInstrucciones
        .whereType<Map<String, dynamic>>()
        .map(RutaStep.fromJson)
        .toList();

    final String? profileValue = json['perfil'] as String?;

    return RutaORSResponse(
      ruta: puntos,
      distanciaM: (json['distancia_m'] as num?)?.toInt() ?? 0,
      duracionS: (json['duracion_s'] as num?)?.toInt() ?? 0,
      instrucciones: instrucciones,
      stepsCount: (json['steps_count'] as num?)?.toInt() ?? instrucciones.length,
      currentStepIndex: (json['current_step_index'] as num?)?.toInt() ?? 0,
      profile: OrsProfileX.fromApiValue(profileValue),
      origen: json['origen'] is Map<String, dynamic>
          ? RutaUbicacion.fromJson(json['origen'] as Map<String, dynamic>)
          : null,
      destino: json['destino'] is Map<String, dynamic>
          ? RutaUbicacion.fromJson(json['destino'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ruta': ruta.map((LatLng punto) => <double>[punto.longitude, punto.latitude]).toList(),
        'distancia_m': distanciaM,
        'duracion_s': duracionS,
        'perfil': profile?.apiValue,
        'instrucciones': instrucciones.map((RutaStep step) => step.toJson()).toList(),
        'steps_count': stepsCount,
        'current_step_index': currentStepIndex,
        if (origen != null) 'origen': origen!.toJson(),
        if (destino != null) 'destino': destino!.toJson(),
      };

  double get distanciaKm => distanciaM / 1000.0;
  double get duracionMin => duracionS / 60.0;
  String get distanciaFormateada => distanciaM < 1000
      ? '${distanciaM}m'
      : '${(distanciaM / 1000).toStringAsFixed(1)}km';
  String get tiempoFormateado => '${duracionMin.round()} min';

  bool get tieneInstrucciones => instrucciones.isNotEmpty;
  RutaStep? get pasoActual =>
      (currentStepIndex >= 0 && currentStepIndex < instrucciones.length) ? instrucciones[currentStepIndex] : null;
}
