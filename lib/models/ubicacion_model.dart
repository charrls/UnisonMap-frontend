class UbicacionModel {
  final int id;
  final String nombre;
  final String tipo;
  final double latitud;
  final double longitud;
  final int piso;

  UbicacionModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.piso,
  });

 factory UbicacionModel.fromJson(Map<String, dynamic> json) {
  return UbicacionModel(
    id: json['id'] ?? -1,
    nombre: (json['nombre'] ?? '').toString(),
    tipo: (json['tipo'] ?? 'otro').toString(),
    latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
    longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
    piso: json['piso'] ?? 1,
  );
}
}
