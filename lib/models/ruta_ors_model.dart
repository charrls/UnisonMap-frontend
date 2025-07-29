import 'package:latlong2/latlong.dart';

class RutaORS {
  final List<LatLng> ruta;
  final int distanciaM;
  final int duracionS;
  final UbicacionInfo origen;
  final UbicacionInfo destino;

  RutaORS({
    required this.ruta,
    required this.distanciaM,
    required this.duracionS,
    required this.origen,
    required this.destino,
  });

  factory RutaORS.fromJson(Map<String, dynamic> json) {
    final rutaData = json['ruta'] as List;
    final coordenadas = rutaData.map((punto) => 
      LatLng(punto['lat'], punto['lng'])
    ).toList();

    return RutaORS(
      ruta: coordenadas,
      distanciaM: json['distancia_m'],
      duracionS: json['duracion_s'],
      origen: UbicacionInfo.fromJson(json['origen']),
      destino: UbicacionInfo.fromJson(json['destino']),
    );
  }

  // Getters de conveniencia
  double get distanciaMetros => distanciaM.toDouble();
  double get tiempoMinutos => (duracionS / 60.0);
  String get distanciaFormateada => distanciaM < 1000 
    ? '${distanciaM}m' 
    : '${(distanciaM / 1000).toStringAsFixed(1)}km';
  String get tiempoFormateado => '${tiempoMinutos.round()} min';
}

class UbicacionInfo {
  final int id;
  final String nombre;
  final double lat;
  final double lng;

  UbicacionInfo({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lng,
  });

  factory UbicacionInfo.fromJson(Map<String, dynamic> json) {
    return UbicacionInfo(
      id: json['id'],
      nombre: json['nombre'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
    );
  }

  // Convertir a LatLng para usar en el mapa
  LatLng get coordenadas => LatLng(lat, lng);
}
