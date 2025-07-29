import 'package:latlong2/latlong.dart';

class RouteModel {
  final List<LatLng> coordenadas;
  final double distanciaMetros;
  final double tiempoMinutos;
  final UbicacionInfo origen;
  final UbicacionInfo destino;

  RouteModel({
    required this.coordenadas,
    required this.distanciaMetros,
    required this.tiempoMinutos,
    required this.origen,
    required this.destino,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final rutaData = json['ruta'] as List;
    final coordenadas = rutaData.map((punto) => 
      LatLng(punto['latitud'], punto['longitud'])
    ).toList();

    return RouteModel(
      coordenadas: coordenadas,
      distanciaMetros: json['distancia_metros'].toDouble(),
      tiempoMinutos: json['tiempo_minutos'].toDouble(),
      origen: UbicacionInfo.fromJson(json['origen']),
      destino: UbicacionInfo.fromJson(json['destino']),
    );
  }
}

class UbicacionInfo {
  final int id;
  final String nombre;
  final double latitud;
  final double longitud;

  UbicacionInfo({
    required this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
  });

  factory UbicacionInfo.fromJson(Map<String, dynamic> json) {
    return UbicacionInfo(
      id: json['id'],
      nombre: json['nombre'],
      latitud: json['latitud'].toDouble(),
      longitud: json['longitud'].toDouble(),
    );
  }
}