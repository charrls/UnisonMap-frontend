import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:unisonmap/models/ubicacion_model.dart';
import '../home_controller.dart';
import '../../../models/route_model.dart' as route_model;
import '../../../models/ruta_ors_model.dart' as ors_model;

class MapView extends StatelessWidget {
  final MapController controller;
  final UbicacionModel? ubicacionSeleccionada;
  final Function(TapPosition, LatLng) onMapTap;
  final bool showRoute;
  final bool selectionMode;
  final LatLng? selectedLocation;
  final NavigationState? navigationState; 
  final UbicacionModel? routeFrom; 
  final UbicacionModel? routeTo; 
  final route_model.RouteModel? currentRoute;
  final ors_model.RutaORS? rutaORS; 


  const MapView({
    super.key,
    required this.controller,
    required this.ubicacionSeleccionada,
    required this.onMapTap,
    this.showRoute = false,
    this.selectionMode = false,
    this.selectedLocation,
    this.navigationState,
    this.routeFrom,
    this.routeTo,
    this.currentRoute,
    this.rutaORS,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        center: const LatLng(29.0819, -110.9628),
        zoom: 17,
        onTap: selectionMode 
          ? (tapPosition, latLng) => onMapTap(tapPosition, latLng)
          : onMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.unisonmap',
        ),
        
        if (rutaORS != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: rutaORS!.ruta,
                strokeWidth: 5.0,
                color: Colors.blueAccent,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white,
              ),
            ],
          ),
        
        if (rutaORS == null && currentRoute != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: currentRoute!.coordenadas,
                strokeWidth: 4.0,
                color: Colors.blue,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white,
              ),
            ],
          ),
        if (navigationState == NavigationState.routePlanning) ...[
          if (routeFrom != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(routeFrom!.latitud, routeFrom!.longitud),
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          if (routeTo != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(routeTo!.latitud, routeTo!.longitud),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
        ],
        
        if (selectionMode && selectedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        
        if (navigationState == NavigationState.normal && ubicacionSeleccionada != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  ubicacionSeleccionada!.latitud,
                  ubicacionSeleccionada!.longitud,
                ),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  size: 36,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        
        if (showRoute)
          PolylineLayer(
            polylines: [
            ],
          ),
        
        if (selectionMode)
          const Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.add_location_alt,
              size: 48,
              color: Colors.red,
            ),
          ),
      ],
    );
  }
}