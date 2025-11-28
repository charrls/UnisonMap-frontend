import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:unisonmap/models/ubicacion_model.dart';

import '../home_controller.dart';
import '../../../models/route_model.dart' as route_model;
import '../../../models/ruta_ors_model.dart' as ors_model;

class MapView extends StatefulWidget {
  const MapView({
    super.key,
    required this.controller,
    required this.ubicacionSeleccionada,
    required this.onMapTap,
    this.showRoute = false,
    this.selectionMode = false,
    this.selectedLocation,
    this.userLocation,
    this.navigationState,
    this.routeFrom,
    this.routeTo,
    this.currentRoute,
    this.rutaORS,
    this.focusedStepMarker,
    this.gesturesEnabled = true,
    this.trackUpEnabled = false,
    this.pendingRoutePolyline,
  });

  final MapController controller;
  final UbicacionModel? ubicacionSeleccionada;
  final Function(TapPosition, LatLng) onMapTap;
  final bool showRoute;
  final bool selectionMode;
  final LatLng? selectedLocation;
  final LatLng? userLocation;
  final NavigationState? navigationState;
  final UbicacionModel? routeFrom;
  final UbicacionModel? routeTo;
  final route_model.RouteModel? currentRoute;
  final ors_model.RutaORSResponse? rutaORS;
  final LatLng? focusedStepMarker;
  final bool gesturesEnabled;
  final bool trackUpEnabled;
  final List<LatLng>? pendingRoutePolyline;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  LatLng? _lastFocusedMarker;

  @override
  void initState() {
    super.initState();
    if (widget.focusedStepMarker != null && widget.navigationState == NavigationState.navigating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnFocusedStep(widget.focusedStepMarker!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusedStepMarker != null &&
        widget.focusedStepMarker != oldWidget.focusedStepMarker &&
        widget.navigationState == NavigationState.navigating) {
      _centerOnFocusedStep(widget.focusedStepMarker!);
    }

    if (widget.focusedStepMarker == null && oldWidget.focusedStepMarker != null) {
      _lastFocusedMarker = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? focusedMarkerRotation = _computeFocusedMarkerRotation();

    return FlutterMap(
      mapController: widget.controller,
      options: MapOptions(
        initialCenter: const LatLng(29.0819, -110.9628),
        initialZoom: 17,
        interactionOptions: InteractionOptions(
          flags: widget.gesturesEnabled ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onTap: widget.selectionMode
            ? (TapPosition tapPosition, LatLng latLng) => widget.onMapTap(tapPosition, latLng)
            : widget.onMapTap,
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.unisonmap',
        ),
        if (widget.userLocation != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: widget.userLocation!,
                width: widget.navigationState == NavigationState.navigating ? 58 : 42,
                height: widget.navigationState == NavigationState.navigating ? 58 : 42,
                child: _UserLocationMarker(
                  navigationMode: widget.navigationState == NavigationState.navigating,
                  trackUp: widget.trackUpEnabled,
                  mapRotationDegrees: widget.controller.camera.rotation,
                ),
              ),
            ],
          ),
        if (widget.showRoute && widget.rutaORS != null) ...<Widget>[
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: widget.rutaORS!.ruta,
                strokeWidth: 4,
                color: Colors.grey.withOpacity(0.4),
              ),
            ],
          ),
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: widget.pendingRoutePolyline?.isNotEmpty == true
                    ? widget.pendingRoutePolyline!
                    : widget.rutaORS!.ruta,
                strokeWidth: 5,
                color: Colors.blueAccent,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),
        ],
        if (widget.showRoute && widget.rutaORS == null && widget.currentRoute != null)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: widget.currentRoute!.coordenadas,
                strokeWidth: 4,
                color: Colors.blue,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),
        if (widget.focusedStepMarker != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: widget.focusedStepMarker!,
                width: 48,
                height: 48,
                child: _FocusedStepMarker(rotationDegrees: focusedMarkerRotation),
              ),
            ],
          ),
        if (widget.navigationState == NavigationState.routePlanning) ...<Widget>[
          if (widget.routeFrom != null)
            MarkerLayer(
              markers: <Marker>[
                Marker(
                  point: LatLng(widget.routeFrom!.latitud, widget.routeFrom!.longitud),
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          if (widget.routeTo != null)
            MarkerLayer(
              markers: <Marker>[
                Marker(
                  point: LatLng(widget.routeTo!.latitud, widget.routeTo!.longitud),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                ),
              ],
            ),
        ],
        if (widget.selectionMode && widget.selectedLocation != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: widget.selectedLocation!,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
              ),
            ],
          ),
        if (widget.navigationState == NavigationState.normal && widget.ubicacionSeleccionada != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: LatLng(
                  widget.ubicacionSeleccionada!.latitud,
                  widget.ubicacionSeleccionada!.longitud,
                ),
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, size: 36, color: Colors.indigo),
              ),
            ],
          ),
        if (widget.selectionMode)
          const Align(
            alignment: Alignment.center,
            child: Icon(Icons.add_location_alt, size: 48, color: Colors.red),
          ),
      ],
    );
  }

  void _centerOnFocusedStep(LatLng target) {
    if (_lastFocusedMarker == target) {
      return;
    }

    _lastFocusedMarker = target;

    try {
      final double currentZoom = widget.controller.camera.zoom;
      final double targetZoom = currentZoom < 17 ? 17 : currentZoom;
      widget.controller.move(target, targetZoom);
    } catch (_) {
    }
  }

  double? _computeFocusedMarkerRotation() {
    final LatLng? marker = widget.focusedStepMarker;
    if (marker == null) {
      return null;
    }

    final List<LatLng> routePoints =
        widget.rutaORS?.ruta ?? widget.currentRoute?.coordenadas ?? const <LatLng>[];
    if (routePoints.length < 2) {
      return null;
    }

    int closestIndex = -1;
    double closestDistance = double.infinity;

    for (int i = 0; i < routePoints.length; i++) {
      final LatLng point = routePoints[i];
      final double dLat = point.latitude - marker.latitude;
      final double dLng = point.longitude - marker.longitude;
      final double distance = dLat * dLat + dLng * dLng;
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    if (closestIndex == -1) {
      return null;
    }

    if (closestIndex < routePoints.length - 1) {
      return _bearingBetween(routePoints[closestIndex], routePoints[closestIndex + 1]);
    }

    if (closestIndex > 0) {
      return _bearingBetween(routePoints[closestIndex - 1], routePoints[closestIndex]);
    }

    return null;
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final double lat1 = _degreesToRadians(from.latitude);
    final double lat2 = _degreesToRadians(to.latitude);
    final double dLon = _degreesToRadians(to.longitude - from.longitude);

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final double bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}

class _FocusedStepMarker extends StatelessWidget {
  const _FocusedStepMarker({this.rotationDegrees});

  final double? rotationDegrees;

  @override
  Widget build(BuildContext context) {
    final Widget marker = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.navigation, color: Colors.blueAccent),
        ),
      ],
    );

    if (rotationDegrees == null) {
      return marker;
    }

    return Transform.rotate(
      angle: rotationDegrees! * math.pi / 180,
      child: marker,
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker({
    required this.navigationMode,
    required this.trackUp,
    required this.mapRotationDegrees,
  });

  final bool navigationMode;
  final bool trackUp;
  final double mapRotationDegrees;

  @override
  Widget build(BuildContext context) {
    if (!navigationMode) {
      return _buildPassiveMarker();
    }

    final double rotationRadians = trackUp ? -mapRotationDegrees * math.pi / 180 : 0;

    return Transform.rotate(
      angle: rotationRadians,
      child: _buildNavigationMarker(),
    );
  }

  Widget _buildPassiveMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
            ),
            child: const Icon(Icons.location_pin, color: Color.fromARGB(255, 255, 255, 255), size: 22),
          ),
        ),
      ],
    );
  }
}

/// Extension utilitaria para ajustar la vista del mapa a una ruta completa.
extension MapControllerRouteExtensions on MapController {
  void showFullRoute(Iterable<LatLng> points, {EdgeInsets padding = const EdgeInsets.all(50)}) {
    if (points.isEmpty) return;
    final iterator = points.iterator;
    iterator.moveNext();
    double minLat = iterator.current.latitude;
    double maxLat = iterator.current.latitude;
    double minLng = iterator.current.longitude;
    double maxLng = iterator.current.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    try {
      fitBounds(bounds, options: FitBoundsOptions(padding: padding));
    } catch (e) {
      debugPrint('No se pudo ajustar los bounds de la ruta: $e');
    }
  }
}