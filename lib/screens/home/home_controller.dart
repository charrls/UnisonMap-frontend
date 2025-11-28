import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/enums/ors_profile.dart';
import '../../data/services/ubicacion_service.dart';
import '../../models/ubicacion_model.dart';
import '../../data/services/ors_service.dart';
import '../../models/ruta_ors_model.dart' as ors_model;
import '../../models/route_model.dart' as route_model;
import 'ruta_controller.dart';
import 'widgets/map_view.dart'; 

enum NavigationState {
  normal,
  routePlanning,
  navigating
}

class HomeController extends ChangeNotifier {
  final UbicacionService _ubicacionService = UbicacionService();
  final ORSService _orsService = ORSService();
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  List<UbicacionModel> ubicaciones = [];
  List<String> historialBusquedas = [];
  List<UbicacionModel> sugerencias = [];
  UbicacionModel? ubicacionSeleccionada;
  bool isLoading = true;
  bool _mostrarPanelBusqueda = false;
  bool get mostrarPanelBusqueda => _mostrarPanelBusqueda;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  final double bottomSheetMaxHeightFraction = 0.4;
  Alignment bottomSheetAlignment = const Alignment(0, 2); 

  late BuildContext context;

  NavigationState _navigationState = NavigationState.normal;
  NavigationState get navigationState => _navigationState;
  
  OrsProfile _selectedProfile = OrsProfile.footWalking;
  final List<OrsProfile> _availableProfiles = List<OrsProfile>.from(kDefaultOrsProfiles);
  final RutaController rutaController = RutaController();
  OrsProfile get selectedProfile => _selectedProfile;
  List<OrsProfile> get availableProfiles => List<OrsProfile>.unmodifiable(_availableProfiles);
  
  bool _showOriginSearchPanel = false;
  bool get showOriginSearchPanel => _showOriginSearchPanel;

  bool _mapSelectionMode = false;
  bool get mapSelectionMode => _mapSelectionMode;
  LatLng? _selectedMapLocation;
  LatLng? get selectedMapLocation => _selectedMapLocation;

  UbicacionModel? _routeFrom;
  UbicacionModel? _routeTo;
  String _distance = '0';
  String _timeEstimate = '0';

  UbicacionModel? get routeFrom => _routeFrom;
  UbicacionModel? get routeTo => _routeTo;
  String get distance => _distance;
  String get timeEstimate => _timeEstimate;
  
  route_model.RouteModel? _currentRoute;
  route_model.RouteModel? get currentRoute => _currentRoute;
  
  ors_model.RutaORSResponse? _rutaORS;
  ors_model.RutaORSResponse? get rutaORS => _rutaORS;

  bool _isCalculatingRoute = false;
  bool get isCalculatingRoute => _isCalculatingRoute;

  bool _isRouteCalculated = false;
  bool get isRouteCalculated => _isRouteCalculated;

  bool _isRecentering = false;
  bool get isRecentering => _isRecentering;

  StreamSubscription<Position>? _navigationSubscription;
  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;
  final Distance _distanceCalculator = const Distance();
  bool _isOffRoute = false;

  bool _isNavigationTrackingActive = false;
  LatLng? _focusedStepMarker;
  LatLng? _lastNavigationLocation;
  double _currentNavigationBearing = 0;
  bool _isControllerMounted = true;
  bool trackUpEnabled = false;
  Timer? _trackUpTicker;
  static const Duration _trackUpInterval = Duration(milliseconds: 80);
  bool _hasRouteBearingReference = false;
  static const double _routeBearingLerpFactor = 0.15;
  static const double _mapRotationOffsetDegrees = -142.0;
  static const double _cameraOffsetMeters = 18;
  static const double _lookAheadMaxMeters = 30;

  List<ors_model.RutaStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  double _currentStepDistanceMeters = double.infinity;
  double? _lastBroadcastedStepDistance;
  bool _hasArrived = false;
  // Métricas para panel inferior compacto (duración restante, distancia restante)
  Duration _remainingDuration = Duration.zero;
  int _remainingDistanceMeters = 0;
  DateTime? _eta;

  // Getters públicos para métricas de navegación
  Duration get remainingDuration => _remainingDuration;
  int get remainingDistanceMeters => _remainingDistanceMeters;
  DateTime? get eta => _eta;
  String get formattedRemainingDistance {
    final int m = _remainingDistanceMeters;
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} km';
    return '$m m';
  }
  String get formattedRemainingDuration {
    final int secs = _remainingDuration.inSeconds;
    if (secs <= 0) return '0m';
    final int minutes = _remainingDuration.inMinutes;
    final int hours = minutes ~/ 60;
    final int remMin = minutes % 60;
    if (hours > 0) {
      if (remMin > 0) return '${hours}h ${remMin}m';
      return '${hours}h';
    }
    return '${minutes}m';
  }
  String get formattedEta {
    if (_eta == null) return '--:--';
    final DateTime e = _eta!;
    final String hh = e.hour.toString().padLeft(2, '0');
    final String mm = e.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  List<ors_model.RutaStep> get navigationSteps => _navigationSteps;
  int get currentStepIndex => _currentStepIndex;
  double get distanceToCurrentStep => _currentStepDistanceMeters;
  bool get hasArrived => _hasArrived;
  bool get hasNavigationSteps => _navigationSteps.isNotEmpty;
  ors_model.RutaStep? get currentStep =>
      (_navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length)
          ? _navigationSteps[_currentStepIndex]
          : null;
  LatLng? get focusedStepMarker => _focusedStepMarker;

  List<LatLng> get pendingRoutePolyline {
    final List<LatLng>? polyline = _rutaORS?.ruta;
    final LatLng? user = _userLocation;

    if (polyline == null || polyline.length < 2) {
      return polyline ?? const <LatLng>[];
    }

    if (user == null) {
      return List<LatLng>.from(polyline);
    }

    return _computePendingPolyline(user, polyline);
  }

  Future<void> init(BuildContext context) async {
    this.context = context;
    
    searchFocusNode.addListener(() {
      if (searchFocusNode.hasFocus) {
        if (!_isSearching) {
          _isSearching = true;
          _mostrarPanelBusqueda = true;
          notifyListeners();
        }
      } else if (_isSearching) {
        closeSearch();
      }
    });
    
    await cargarUbicaciones();
    await cargarHistorial();
    isLoading = false;
    notifyListeners();
  }

  Future<void> calcularRuta() async {
    if (routeFrom == null || routeTo == null) {
      print('Error: No se puede calcular ruta, faltan ubicaciones');
      return;
    }

    _resetNavigationGuidance();
    _isCalculatingRoute = true;
    notifyListeners();

    try {
    print('Intentando obtener ruta ORS desde ${routeFrom!.nombre} hasta ${routeTo!.nombre}');

    final OrsProfile profile = _selectedProfile;
      final useCoordinateRouting =
          _requiresCoordinateRouting(routeFrom!) || _requiresCoordinateRouting(routeTo!);

    ors_model.RutaORSResponse? rutaORS;

      if (useCoordinateRouting) {
        rutaORS = await _orsService.obtenerRutaPorCoordenadas(
          origenLat: routeFrom!.latitud,
          origenLng: routeFrom!.longitud,
          destinoLat: routeTo!.latitud,
          destinoLng: routeTo!.longitud,
          profile: profile,
        );
      } else {
        rutaORS = await _orsService.obtenerRutaReal(
          desdeId: routeFrom!.id,
          haciaId: routeTo!.id,
          profile: profile,
        );
      }
      
      if (rutaORS != null) {
        print('Ruta ORS obtenida exitosamente');
        _rutaORS = rutaORS;
        rutaController.setRuta(rutaORS);
        _currentRoute = null; 
        _applyNavigationStepsFromRoute(_rutaORS);
        
        _distance = rutaORS.distanciaFormateada;
        _timeEstimate = rutaORS.tiempoFormateado;
        
        if (rutaORS.ruta.isNotEmpty) {
          _adjustMapBounds(rutaORS.ruta);
        }
        
        print('Distancia: ${rutaORS.distanciaFormateada}, Tiempo: ${rutaORS.tiempoFormateado}');
        
        _isRouteCalculated = true; 
        
      } else {
        print('Ruta ORS no disponible, intentando ruta legacy...');
        
        await _calcularRutaLegacy();
      }
      
    } on RouteRequestException catch (e) {
      _showSnackBar(e.message);
      if (e.allowedProfiles != null && e.allowedProfiles!.isNotEmpty) {
        _syncAvailableProfiles(e.allowedProfiles!);
      }
      await _calcularRutaLegacy();
    } catch (e) {
      print('Error obteniendo ruta ORS: \$e');
      
      await _calcularRutaLegacy();
    } finally {
      _isCalculatingRoute = false;
      notifyListeners();
    }
  }

  Future<void> _calcularRutaLegacy() async {
    try {
      print('Obteniendo ruta legacy...');
      
      _createDirectRoute();
      
    } catch (e) {
      print('Error con ruta legacy: \$e');
      
      _createDirectRoute();
    }
  }

  bool _requiresCoordinateRouting(UbicacionModel ubicacion) {
    if (ubicacion.id <= 0) {
      return true;
    }

    final tipo = ubicacion.tipo.toLowerCase();
    return tipo == 'ubicacion_actual' || tipo == 'ubicacion_seleccionada' || tipo == 'personalizada';
  }

  Future<void> _createDirectRoute() async {
    print('Creando ruta directa como fallback');
    
    final directRoute = [
      LatLng(routeFrom!.latitud, routeFrom!.longitud),
      LatLng(routeTo!.latitud, routeTo!.longitud),
    ];
    
    final distanceInMeters = Geolocator.distanceBetween(
      routeFrom!.latitud,
      routeFrom!.longitud,
      routeTo!.latitud,
      routeTo!.longitud,
    );
    
    final timeInMinutes = (distanceInMeters / 1.4 / 60).round();
    
    final int distanciaTotal = distanceInMeters.round();
    final int duracionTotal = timeInMinutes * 60;

    final List<ors_model.RutaStep> pasos = <ors_model.RutaStep>[
      ors_model.RutaStep.manual(
        orden: 0,
        texto: 'Sigue caminando recto hasta ${routeTo!.nombre}',
        distanceM: distanciaTotal,
        durationS: duracionTotal,
        location: ors_model.RutaUbicacion(
          lat: routeTo!.latitud,
          lng: routeTo!.longitud,
        ),
      ),
    ];

    _rutaORS = ors_model.RutaORSResponse(
      ruta: directRoute,
      distanciaM: distanciaTotal,
      duracionS: duracionTotal,
      instrucciones: pasos,
      stepsCount: pasos.length,
      currentStepIndex: 0,
      profile: _selectedProfile,
      origen: ors_model.RutaUbicacion(
        lat: routeFrom!.latitud,
        lng: routeFrom!.longitud,
      ),
      destino: ors_model.RutaUbicacion(
        lat: routeTo!.latitud,
        lng: routeTo!.longitud,
      ),
    );

    rutaController.setRuta(_rutaORS);

    _currentRoute = null;
    _distance = _rutaORS!.distanciaFormateada;
    _timeEstimate = _rutaORS!.tiempoFormateado;

    _adjustMapBounds(directRoute);

    _isRouteCalculated = true;
    _applyNavigationStepsFromRoute(_rutaORS);

    print('Distancia directa: $_distance, Tiempo estimado: $_timeEstimate');
  }

  void _adjustMapBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    
    final padding = 0.001;
    final bounds = LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
    
    try {
      mapController.fitBounds(bounds, options: const FitBoundsOptions(padding: EdgeInsets.all(50)));
    } catch (e) {
      print('Error ajustando bounds del mapa: \$e');
    }
  }

  Future<void> cargarUbicaciones() async {
    try {
      ubicaciones = await _ubicacionService.fetchUbicaciones();
    } catch (e) {
      print('Error cargando ubicaciones: \$e');
      ubicaciones = [];
    }
  }

  Future<void> cargarHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      historialBusquedas = prefs.getStringList('historial_busquedas') ?? [];
    } catch (e) {
      print('Error cargando historial: \$e');
    }
  }

  Future<void> guardarEnHistorial(String busqueda) async {
    try {
      if (!historialBusquedas.contains(busqueda)) {
        historialBusquedas.insert(0, busqueda);
        if (historialBusquedas.length > 10) {
          historialBusquedas = historialBusquedas.take(10).toList();
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('historial_busquedas', historialBusquedas);
      }
    } catch (e) {
      print('Error guardando en historial: \$e');
    }
  }

  void actualizarSugerencias(String texto) {
    if (texto.isEmpty) {
      sugerencias = [];
    } else {
      final textoLower = texto.toLowerCase().trim();
      
      final coincidenciasExactas = <UbicacionModel>[];
      final coincidenciasIniciales = <UbicacionModel>[];
      final coincidenciasInternas = <UbicacionModel>[];
      
      for (final ubicacion in ubicaciones) {
        final nombreLower = ubicacion.nombre.toLowerCase();
        final tipoLower = ubicacion.tipo.toLowerCase();
        
        if (nombreLower == textoLower) {
          coincidenciasExactas.add(ubicacion);
        }
        else if (nombreLower.startsWith(textoLower)) {
          coincidenciasIniciales.add(ubicacion);
        }
        else if (nombreLower.contains(textoLower) || tipoLower.contains(textoLower)) {
          coincidenciasInternas.add(ubicacion);
        }
      }
      
      sugerencias = [
        ...coincidenciasExactas,
        ...coincidenciasIniciales,
        ...coincidenciasInternas,
      ].take(10).toList();
    }
    notifyListeners();
  }

  void buscarUbicacion(dynamic ubicacionOTexto) {
    UbicacionModel? ubicacionEncontrada;

    if (ubicacionOTexto is UbicacionModel) {
      ubicacionEncontrada = ubicacionOTexto;
    } else if (ubicacionOTexto is String) {
      ubicacionEncontrada = ubicaciones.firstWhere(
        (ubicacion) => ubicacion.nombre.toLowerCase() == ubicacionOTexto.toLowerCase(),
        orElse: () => ubicaciones.first,
      );
    }

    if (ubicacionEncontrada != null) {
      final wasSearching = _isSearching;
      ubicacionSeleccionada = ubicacionEncontrada;
      mapController.move(
        LatLng(ubicacionEncontrada.latitud, ubicacionEncontrada.longitud),
        17,
      );
      searchController.text = ubicacionEncontrada.nombre;
      bottomSheetAlignment = const Alignment(0, 1);
      guardarEnHistorial(ubicacionEncontrada.nombre);
      final didNotify = closeSearch();

      if (!wasSearching && !didNotify) {
        notifyListeners();
      }
    }
  }


  void startSearch() {
    if (_isSearching) {
      return;
    }

    _isSearching = true;
    _mostrarPanelBusqueda = true;

    if (!searchFocusNode.hasFocus) {
      searchFocusNode.requestFocus();
    }

    notifyListeners();
  }

  bool closeSearch({bool clearQuery = false}) {
    var shouldNotify = false;

    if (clearQuery && searchController.text.isNotEmpty) {
      searchController.clear();
      shouldNotify = true;
    }

    if (sugerencias.isNotEmpty) {
      sugerencias = [];
      shouldNotify = true;
    }

    if (_mostrarPanelBusqueda) {
      _mostrarPanelBusqueda = false;
      shouldNotify = true;
    }

    if (!_isSearching) {
      if (shouldNotify) {
        notifyListeners();
      }
      return shouldNotify;
    }

    _isSearching = false;
    shouldNotify = true;

    if (searchFocusNode.hasFocus) {
      searchFocusNode.unfocus();
    }

    if (shouldNotify) {
      notifyListeners();
    }

    return shouldNotify;
  }


double getBottomSheetCurrentHeight(double screenHeight) {
  if (ubicacionSeleccionada == null) return 0;
  
  final sheetHeight = screenHeight * 0.285; 
  final alignmentY = bottomSheetAlignment.y;
  
  if (alignmentY >= 2.0) {
    return 0; 
  } else if (alignmentY <= 1.0) {
    return sheetHeight; 
  } else {
    final visibilityFactor = (2.0 - alignmentY) / 1.0;
    return sheetHeight * visibilityFactor;
  }
}
  void updateSearchPanelVisibility() {
    if (!_isSearching) {
      if (_mostrarPanelBusqueda) {
        _mostrarPanelBusqueda = false;
        notifyListeners();
      }
      return;
    }

    final shouldShow = searchController.text.isNotEmpty || historialBusquedas.isNotEmpty;

    if (_mostrarPanelBusqueda != shouldShow) {
      _mostrarPanelBusqueda = shouldShow;
      notifyListeners();
    }
  }

  void handleBottomSheetDrag(DragUpdateDetails details) {
    if (details.delta.dy > 5) { 
      bottomSheetAlignment = const Alignment(0, 2); 
    } else if (details.delta.dy < -5) { 
      bottomSheetAlignment = const Alignment(0, 1);
    }
    notifyListeners();
  }

  void expandBottomSheet() {
    bottomSheetAlignment = const Alignment(0, 1); 
    notifyListeners();
  }

  void setTrackUpEnabled(bool value) {
    if (trackUpEnabled == value) {
      return;
    }

    trackUpEnabled = value;
    _hasRouteBearingReference = false;

    if (trackUpEnabled) {
      _startTrackUpTicker();
      _updateTrackUpCamera(force: true);
    } else {
      _stopTrackUpTicker();
      _currentNavigationBearing = 0;
      if (_isControllerMounted) {
        try {
          mapController.rotate(0);
        } catch (_) {
        }
      }
    }

    notifyListeners();
  }

  Future<void> centrarEnUbicacionActual() async {
    if (_isRecentering) {
      return;
    }

    try {
      final serviceEnabled = await _ensureLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      final permissionGranted = await _ensureLocationPermission();
      if (!permissionGranted) {
        return;
      }

      _isRecentering = true;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final target = LatLng(position.latitude, position.longitude);
      _updateUserLocation(target, notify: false);
      await _animateCameraTo(target, zoom: 17.5);

      ubicacionSeleccionada = null;
      bottomSheetAlignment = const Alignment(0, 2);

      notifyListeners();
    } on PermissionDeniedException {
      _showSnackBar('No se pudo obtener tu ubicación. Revisa los permisos.');
    } on LocationServiceDisabledException {
      _showSnackBar(
        'Activa el GPS para centrar el mapa.',
        action: SnackBarAction(
          label: 'Abrir ajustes',
          onPressed: () {
            Geolocator.openLocationSettings();
          },
        ),
      );
    } catch (e) {
      _showSnackBar('Ocurrió un problema al obtener tu ubicación.');
      print('Error obteniendo ubicación: $e');
    } finally {
      _isRecentering = false;
    }
  }

  Future<bool> _ensureLocationServiceEnabled() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      return true;
    }

    _showSnackBar(
      'El GPS está desactivado.',
      action: SnackBarAction(
        label: 'Activar',
        onPressed: () {
          Geolocator.openLocationSettings();
        },
      ),
    );
    return false;
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showSnackBar('Se necesitan permisos de ubicación para centrar el mapa.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        'Los permisos de ubicación están deshabilitados permanentemente.',
        action: SnackBarAction(
          label: 'Configuración',
          onPressed: () {
            Geolocator.openAppSettings();
          },
        ),
      );
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }


  Future<bool> _startNavigationTracking({int distanceFilter = 4}) async {
    if (_isNavigationTrackingActive) {
      return true;
    }

    final serviceEnabled = await _ensureLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    final permissionGranted = await _ensureLocationPermission();
    if (!permissionGranted) {
      return false;
    }

    await _navigationSubscription?.cancel();

    final navigationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: distanceFilter,
    );

    _navigationSubscription = Geolocator
        .getPositionStream(locationSettings: navigationSettings)
        .listen((position) {
      final location = LatLng(position.latitude, position.longitude);
      final didChange = _updateUserLocation(location);
      if (_navigationState == NavigationState.navigating && didChange) {
        _handleNavigationLocationUpdate(position);
      }
    }, onError: (error) {
      debugPrint('Error en el seguimiento de navegación: $error');
    });

    _isNavigationTrackingActive = true;
    _lastNavigationLocation = null;
    if (trackUpEnabled) {
      _startTrackUpTicker();
    }
    return true;
  }

  Future<void> _stopNavigationTracking() async {
    if (!_isNavigationTrackingActive) {
      return;
    }

    await _navigationSubscription?.cancel();
    _navigationSubscription = null;
    _isNavigationTrackingActive = false;
    _lastNavigationLocation = null;
    _currentNavigationBearing = 0;
    _stopTrackUpTicker();

    try {
      if (_isControllerMounted) {
        mapController.rotate(0);
      }
    } catch (e) {
      debugPrint('No se pudo resetear la rotación del mapa: $e');
    }
  }

  void _handleNavigationLocationUpdate(Position position) {
    final LatLng current = LatLng(position.latitude, position.longitude);
    _updateNavigationStepProgress(current);
    _checkOffRouteAndMaybeRecalculate(current);
    _lastNavigationLocation = current;

    if (trackUpEnabled) {
      _updateTrackUpCamera();
      return;
    }

    if (!_isControllerMounted || _navigationState != NavigationState.navigating) {
      return;
    }

    final double zoom = _resolveNavigationZoom();
    mapController.move(current, zoom);
  }

  void _startTrackUpTicker() {
    if (_trackUpTicker != null) {
      return;
    }

    _trackUpTicker = Timer.periodic(_trackUpInterval, (_) {
      _updateTrackUpCamera();
    });
  }

  void _stopTrackUpTicker() {
    _trackUpTicker?.cancel();
    _trackUpTicker = null;
  }

  void _updateTrackUpCamera({bool force = false}) {
    if (!trackUpEnabled || _navigationState != NavigationState.navigating) {
      return;
    }

    if (!_isControllerMounted) {
      return;
    }

    final LatLng? user = _userLocation ?? _lastNavigationLocation;
    final List<LatLng>? route = _rutaORS?.ruta ?? _currentRoute?.coordenadas;

    if (user == null || route == null || route.length < 2) {
      return;
    }

    final _RouteMatchResult? match = _matchPositionToRoute(user, route);
    if (match == null) {
      return;
    }

    final double lookAheadMeters = _resolveRouteLookAheadDistance();
    final LatLng lookAheadPoint = _computeLookAheadPoint(match, route, lookAheadMeters);
    final double bearing = _computeBearingBetween(match.projection, lookAheadPoint);
    if (!bearing.isFinite) {
      return;
    }

    final double smoothedBearing = _smoothRouteBearing(bearing);
    final LatLng cameraTarget = _cameraCenterFromUser(user, smoothedBearing, lookAheadMeters);
    _applyTrackUpCameraUpdate(cameraTarget, smoothedBearing, force: force);
  }

  _RouteMatchResult? _matchPositionToRoute(LatLng user, List<LatLng> polyline) {
    if (polyline.length < 2) {
      return null;
    }

    double closestDistance = double.infinity;
    _RouteMatchResult? bestResult;

    for (int i = 0; i < polyline.length - 1; i++) {
      final LatLng a = polyline[i];
      final LatLng b = polyline[i + 1];
      final _ProjectionResult projection = _projectOnSegment(user, a, b);
      if (!projection.distance.isFinite) {
        continue;
      }
      if (projection.distance < closestDistance) {
        closestDistance = projection.distance;
        bestResult = _RouteMatchResult(
          projection: projection.point,
          segmentIndex: i,
          segmentFraction: projection.t,
        );
      }
    }

    return bestResult;
  }

  LatLng _computeLookAheadPoint(
    _RouteMatchResult match,
    List<LatLng> polyline,
    double aheadMeters,
  ) {
    double remaining = aheadMeters;
    LatLng cursor = match.projection;
    int segmentIndex = match.segmentIndex;

    while (segmentIndex < polyline.length - 1) {
      final LatLng segmentEnd = polyline[segmentIndex + 1];
      final double segmentDistance = Geolocator.distanceBetween(
        cursor.latitude,
        cursor.longitude,
        segmentEnd.latitude,
        segmentEnd.longitude,
      );

      if (!segmentDistance.isFinite || segmentDistance <= 0) {
        cursor = segmentEnd;
        segmentIndex++;
        continue;
      }

      if (segmentDistance >= remaining) {
        final double t = (remaining / segmentDistance).clamp(0.0, 1.0);
        final double? lat = lerpDouble(cursor.latitude, segmentEnd.latitude, t);
        final double? lng = lerpDouble(cursor.longitude, segmentEnd.longitude, t);
        if (lat == null || lng == null) {
          return segmentEnd;
        }
        return LatLng(lat, lng);
      }

      remaining -= segmentDistance;
      cursor = segmentEnd;
      segmentIndex++;
    }

    return polyline.last;
  }

  double _computeBearingBetween(LatLng from, LatLng to) {
    return _normalizeBearing(
      Geolocator.bearingBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      ),
    );
  }

  double _resolveRouteLookAheadDistance() {
    switch (_selectedProfile) {
      case OrsProfile.footWalking:
        return 18;
      case OrsProfile.cyclingRegular:
        return 24;
      case OrsProfile.drivingCar:
        return 30;
    }
  }

  LatLng _cameraCenterFromUser(LatLng user, double bearing, double lookAheadMeters) {
    final double offsetMeters = (lookAheadMeters * 0.65).clamp(_cameraOffsetMeters, _lookAheadMaxMeters);
    final LatLng ahead = _distanceCalculator.offset(user, offsetMeters, bearing);
    return ahead;
  }

  double _smoothRouteBearing(double target) {
    final double normalized = _normalizeBearing(target);
    if (!_hasRouteBearingReference) {
      _hasRouteBearingReference = true;
      _currentNavigationBearing = normalized;
      return normalized;
    }

    final double diff = _bearingDifference(normalized, _currentNavigationBearing);
    _currentNavigationBearing = _normalizeBearing(
      _currentNavigationBearing + diff * _routeBearingLerpFactor,
    );
    return _currentNavigationBearing;
  }

  void _applyTrackUpCameraUpdate(LatLng target, double bearing, {bool force = false}) {
    if (!_isControllerMounted) {
      return;
    }

    final camera = mapController.camera;
    final double desiredZoom = _resolveNavigationZoom();

    final double lerpFactor = force ? 1.0 : 0.35;
    final double targetLat = lerpDouble(camera.center.latitude, target.latitude, lerpFactor)!;
    final double targetLng = lerpDouble(camera.center.longitude, target.longitude, lerpFactor)!;
    final double zoom = force ? desiredZoom : lerpDouble(camera.zoom, desiredZoom, 0.12)!;
    final double normalizedBearing = _normalizeBearing(bearing + _mapRotationOffsetDegrees);
    final double rotation = force
        ? normalizedBearing
        : _normalizeBearing(
            camera.rotation + _bearingDifference(normalizedBearing, camera.rotation) * 0.2,
          );

    mapController.move(LatLng(targetLat, targetLng), zoom);
    try {
      mapController.rotate(rotation);
    } catch (_) {
    }
  }

  _ProjectionResult _projectOnSegment(LatLng p, LatLng a, LatLng b) {
    final double ax = a.longitude;
    final double ay = a.latitude;
    final double bx = b.longitude;
    final double by = b.latitude;
    final double px = p.longitude;
    final double py = p.latitude;

    final double abx = bx - ax;
    final double aby = by - ay;
    final double apx = px - ax;
    final double apy = py - ay;

    final double abLen2 = abx * abx + aby * aby;
    double t = abLen2 > 0 ? (apx * abx + apy * aby) / abLen2 : 0;
    t = t.clamp(0.0, 1.0);

    final double projX = ax + abx * t;
    final double projY = ay + aby * t;
    final LatLng projection = LatLng(projY, projX);
    final double distance = Geolocator.distanceBetween(py, px, projY, projX);

    return _ProjectionResult(point: projection, distance: distance, t: t);
  }


  void _checkOffRouteAndMaybeRecalculate(LatLng currentPosition) {
    if (_navigationState != NavigationState.navigating || _routeTo == null) {
      return;
    }

    final List<LatLng>? polyline = _rutaORS?.ruta;
    if (polyline == null || polyline.length < 2) {
      return;
    }

    final double distanceToRoute = _distanceToRoutePolyline(currentPosition, polyline);

    // Si está a más de 35 m de la polilínea, se considera desvío
    const double offRouteThresholdMeters = 35;

    final bool nowOffRoute = distanceToRoute.isFinite && distanceToRoute > offRouteThresholdMeters;

    if (!nowOffRoute) {
      _isOffRoute = false;
      return;
    }

    if (_isOffRoute || _isCalculatingRoute) {
      return;
    }

    _isOffRoute = true;

    // Recalcular ruta desde la posición actual hsta el mismo destino.
    final UbicacionModel newOrigin = UbicacionModel(
      id: -500,
      nombre: 'Tu ubicación',
      tipo: 'ubicacion_actual',
      latitud: currentPosition.latitude,
      longitud: currentPosition.longitude,
      piso: 1,
    );

    _routeFrom = newOrigin;

    unawaited(_recalculateRouteFromCurrentPosition());
  }

  double _distanceToRoutePolyline(LatLng position, List<LatLng> polyline) {
    if (polyline.length < 2) {
      return double.infinity;
    }

    double minDistance = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      final LatLng a = polyline[i];
      final LatLng b = polyline[i + 1];

      final double segmentDistance = _distanceToSegmentMeters(position, a, b);
      if (segmentDistance.isFinite && segmentDistance < minDistance) {
        minDistance = segmentDistance;
      }
    }

    return minDistance;
  }

  double _distanceToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final double ax = a.longitude;
    final double ay = a.latitude;
    final double bx = b.longitude;
    final double by = b.latitude;
    final double px = p.longitude;
    final double py = p.latitude;

    final double abx = bx - ax;
    final double aby = by - ay;
    final double apx = px - ax;
    final double apy = py - ay;

    final double abLen2 = abx * abx + aby * aby;
    if (abLen2 <= 0) {
      return Geolocator.distanceBetween(ay, ax, py, px);
    }

    double t = (apx * abx + apy * aby) / abLen2;
    if (t < 0) t = 0;
    if (t > 1) t = 1;

    final double projX = ax + abx * t;
    final double projY = ay + aby * t;

    return Geolocator.distanceBetween(py, px, projY, projX);
  }

  Future<void> _recalculateRouteFromCurrentPosition() async {
    if (_routeFrom == null || _routeTo == null) {
      return;
    }

    _isCalculatingRoute = true;
    notifyListeners();

    try {
      final OrsProfile profile = _selectedProfile;
      final bool useCoordinateRouting =
          _requiresCoordinateRouting(_routeFrom!) || _requiresCoordinateRouting(_routeTo!);

      ors_model.RutaORSResponse? rutaORS;

      if (useCoordinateRouting) {
        rutaORS = await _orsService.obtenerRutaPorCoordenadas(
          origenLat: _routeFrom!.latitud,
          origenLng: _routeFrom!.longitud,
          destinoLat: _routeTo!.latitud,
          destinoLng: _routeTo!.longitud,
          profile: profile,
        );
      } else {
        rutaORS = await _orsService.obtenerRutaReal(
          desdeId: _routeFrom!.id,
          haciaId: _routeTo!.id,
          profile: profile,
        );
      }

      if (rutaORS != null) {
        _rutaORS = rutaORS;
        rutaController.setRuta(rutaORS);
        _currentRoute = null;
        _applyNavigationStepsFromRoute(_rutaORS);

        _distance = rutaORS.distanciaFormateada;
        _timeEstimate = rutaORS.tiempoFormateado;

        _isRouteCalculated = true;
        _isOffRoute = false;
      }
    } catch (_) {
    } finally {
      _isCalculatingRoute = false;
      notifyListeners();
    }
  }


  void _updateNavigationStepProgress(LatLng location) {
    if (_navigationState != NavigationState.navigating || _navigationSteps.isEmpty) {
      return;
    }

    if (_hasArrived) {
      return;
    }

    final step = _navigationSteps[_currentStepIndex];
    final target = _resolveStepTarget(step);

    if (target == null) {
      return;
    }

    final distance = Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      target.latitude,
      target.longitude,
    );

    _currentStepDistanceMeters = distance;

    const thresholdMeters = 8.0;

    if (distance <= thresholdMeters) {
      if (_currentStepIndex < _navigationSteps.length - 1) {
        _currentStepIndex++;
        _currentStepDistanceMeters = double.infinity;
        _lastBroadcastedStepDistance = null;


        if (trackUpEnabled) {
          _updateTrackUpCamera(force: true);
        }

        _recalculateRemainingMetrics();
        notifyListeners();
      } else {
        _hasArrived = true;
        _currentStepDistanceMeters = 0;
        _lastBroadcastedStepDistance = 0;
         _remainingDuration = Duration.zero;
         _remainingDistanceMeters = 0;
         _eta = DateTime.now();
        notifyListeners();
      }
      return;
    }

    if (_lastBroadcastedStepDistance == null ||
        (_lastBroadcastedStepDistance! - distance).abs() > 1) {
      _lastBroadcastedStepDistance = distance;
      _recalculateRemainingMetrics();
      notifyListeners();
    }
  }

  void _recalculateRemainingMetrics() {
    if (_navigationSteps.isEmpty) {
      _remainingDuration = Duration.zero;
      _remainingDistanceMeters = 0;
      _eta = null;
      return;
    }
    int totalDistance = 0;
    int totalDurationS = 0;
    for (int i = _currentStepIndex; i < _navigationSteps.length; i++) {
      final ors_model.RutaStep s = _navigationSteps[i];
      totalDistance += s.distanceM;
      totalDurationS += s.durationS;
    }
    if (_currentStepDistanceMeters.isFinite && _currentStepDistanceMeters > 0 && _currentStepIndex < _navigationSteps.length) {
      final int planned = _navigationSteps[_currentStepIndex].distanceM;
      if (_currentStepDistanceMeters < planned) {
        totalDistance -= planned;
        totalDistance += _currentStepDistanceMeters.round();
      }
    }
    _remainingDistanceMeters = totalDistance;
    _remainingDuration = Duration(seconds: totalDurationS);
    _eta = DateTime.now().add(_remainingDuration);
  }


  Future<UbicacionModel?> _buildCurrentLocationOrigin() async {
    final serviceEnabled = await _ensureLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    final permissionGranted = await _ensureLocationPermission();
    if (!permissionGranted) {
      return null;
    }

    LatLng? location = _userLocation;
    if (location == null) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        location = LatLng(position.latitude, position.longitude);
        _updateUserLocation(location, notify: false);
      } catch (e) {
        debugPrint('No se pudo obtener la ubicación actual: $e');
        return null;
      }
    }

    return UbicacionModel(
      id: -500,
      nombre: 'Tu ubicación',
      tipo: 'ubicacion_actual',
      latitud: location.latitude,
      longitud: location.longitude,
      piso: 1,
    );
  }

  bool _updateUserLocation(LatLng location, {bool notify = true}) {
    final current = _userLocation;
    final hasChanged = current == null ||
        (current.latitude - location.latitude).abs() > 1e-7 ||
        (current.longitude - location.longitude).abs() > 1e-7;

    if (hasChanged) {
      _userLocation = location;
      if (notify) {
        notifyListeners();
      }
    }

    return hasChanged;
  }

  Future<void> _waitForMapReady() async {
    if (!_isControllerMounted) {
      return;
    }
    bool waitedForFrame = false;
    try {
      final dynamic controller = mapController;
      final dynamic readyFuture = controller.mapReady;
      if (readyFuture is Future) {
        await readyFuture;
      } else {
        throw StateError('mapReady is not a Future');
      }
    } catch (_) {
      if (!_isControllerMounted) {
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
      waitedForFrame = true;
    }

    if (!_isControllerMounted) {
      return;
    }

    if (!waitedForFrame) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _animateCameraTo(LatLng target, {double? zoom, double? rotation}) async {
    if (!_isControllerMounted) {
      return;
    }
    await _waitForMapReady();
    if (!_isControllerMounted) {
      return;
    }
    final currentCamera = mapController.camera;
    final startCenter = currentCamera.center;
    final startZoom = currentCamera.zoom;
    final targetZoom = zoom ?? startZoom;
    final startRotation = currentCamera.rotation;
    final targetRotation = rotation ?? startRotation;

    const duration = Duration(milliseconds: 450);
    const steps = 30;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);

    final double rotDelta = _bearingDifference(targetRotation, startRotation);
    for (var i = 1; i <= steps; i++) {
      final t = Curves.easeOutCubic.transform(i / steps);
      final interpolatedLat = lerpDouble(startCenter.latitude, target.latitude, t)!;
      final interpolatedLng = lerpDouble(startCenter.longitude, target.longitude, t)!;
      final interpolatedZoom = lerpDouble(startZoom, targetZoom, t)!;
      final interpolatedRotation = _normalizeBearing(startRotation + rotDelta * t);

      mapController.move(LatLng(interpolatedLat, interpolatedLng), interpolatedZoom);
      try {
        mapController.rotate(interpolatedRotation);
      } catch (e) {
        debugPrint('Error al rotar mapa: $e');
      }

      if (i < steps) {
        await Future.delayed(stepDuration);
      }
    }
  }

  double _normalizeBearing(double value) => (value % 360 + 360) % 360;

  double _bearingDifference(double a, double b) {
    final double diff = (a - b + 540) % 360 - 180;
    return diff;
  }

  double _resolveNavigationZoom() {
    switch (_selectedProfile) {
      case OrsProfile.footWalking:
        return 17.5;
      case OrsProfile.cyclingRegular:
        return 16.0;
      case OrsProfile.drivingCar:
        return 15.0;
    }
  }


  LatLng? _resolveStepTarget(ors_model.RutaStep step) {
    if (step.location != null) {
      return step.location!.toLatLng();
    }

    if (_rutaORS != null) {
      if (_rutaORS!.ruta.isNotEmpty) {
        return _rutaORS!.ruta.last;
      }
    }

    if (routeTo != null) {
      return LatLng(routeTo!.latitud, routeTo!.longitud);
    }

    return null;
  }

  List<LatLng> _computePendingPolyline(LatLng user, List<LatLng> polyline) {
    if (polyline.length < 2) {
      return List<LatLng>.from(polyline);
    }

    int closestIndex = 0;
    double closestDistance = double.infinity;

    for (int i = 0; i < polyline.length; i++) {
      final LatLng p = polyline[i];
      final double d = Geolocator.distanceBetween(
        user.latitude,
        user.longitude,
        p.latitude,
        p.longitude,
      );
      if (!d.isFinite) continue;
      if (d < closestDistance) {
        closestDistance = d;
        closestIndex = i;
      }
    }

    if (closestIndex >= polyline.length - 1) {
      return <LatLng>[polyline.last];
    }

    final LatLng a = polyline[closestIndex];
    final LatLng b = polyline[closestIndex + 1];

    final double ax = a.longitude;
    final double ay = a.latitude;
    final double bx = b.longitude;
    final double by = b.latitude;
    final double ux = user.longitude;
    final double uy = user.latitude;

    final double vx = bx - ax;
    final double vy = by - ay;
    final double wx = ux - ax;
    final double wy = uy - ay;

    final double vv = vx * vx + vy * vy;
    double t = vv > 0 ? (wx * vx + wy * vy) / vv : 0.0;
    t = t.clamp(0.0, 1.0);

    final double projLat = ay + vy * t;
    final double projLng = ax + vx * t;
    final LatLng projected = LatLng(projLat, projLng);

    final List<LatLng> pending = <LatLng>[];
    pending.add(projected);
    for (int i = closestIndex + 1; i < polyline.length; i++) {
      pending.add(polyline[i]);
    }

    return pending;
  }

  void _resetNavigationGuidance() {
    _navigationSteps = [];
    _currentStepIndex = 0;
    _currentStepDistanceMeters = double.infinity;
    _lastBroadcastedStepDistance = null;
    _hasArrived = false;
    _focusedStepMarker = null;
    _remainingDuration = Duration.zero;
    _remainingDistanceMeters = 0;
    _eta = null;
    _hasRouteBearingReference = false;
    rutaController.limpiarRuta();
  }

  void _applyNavigationStepsFromRoute(ors_model.RutaORSResponse? ruta) {
    if (ruta == null) {
      _resetNavigationGuidance();
      return;
    }

    final List<ors_model.RutaStep> pasos = ruta.instrucciones.isNotEmpty
        ? List<ors_model.RutaStep>.from(ruta.instrucciones)
        : _buildDefaultSteps(ruta);

    _navigationSteps = pasos;
    _currentStepIndex = ruta.currentStepIndex.clamp(0, pasos.isEmpty ? 0 : pasos.length - 1);
    _currentStepDistanceMeters = double.infinity;
    _lastBroadcastedStepDistance = null;
    _hasArrived = false;

    rutaController.setRuta(ruta);
    rutaController.sincronizarIndiceBackend(_currentStepIndex);
    rutaController.setFocusListener(_handleStepFocus);
    _recalculateRemainingMetrics();
  }

  void _handleStepFocus(ors_model.RutaStep? step) {
    _currentStepIndex = rutaController.pasoActual;

    LatLng? target;
    if (step != null) {
      target = _resolveStepTarget(step);
    }

    _focusedStepMarker = target;

    // Solo recentrar automáticamente durante navegación
    if (target != null && _navigationState == NavigationState.navigating) {
      unawaited(_animateCameraTo(target, zoom: mapController.camera.zoom));
    }

    notifyListeners();
  }

  List<ors_model.RutaStep> _buildDefaultSteps(ors_model.RutaORSResponse ruta) {
    final LatLng? destino = ruta.destino?.toLatLng() ??
        (ruta.ruta.isNotEmpty ? ruta.ruta.last : null);

    return <ors_model.RutaStep>[
      ors_model.RutaStep.manual(
        orden: 0,
        texto: 'Sigue caminando recto',
        distanceM: ruta.distanciaM,
        durationS: ruta.duracionS,
        location: destino != null
            ? ors_model.RutaUbicacion(lat: destino.latitude, lng: destino.longitude)
            : null,
      ),
    ];
  }

  String getStepDescription(ors_model.RutaStep step) {
    return step.texto.isNotEmpty ? step.texto : 'Continúa hacia tu destino';
  }

  IconData getStepIcon(ors_model.RutaStep step) {
    final String texto = step.texto.toLowerCase();

    if (texto.contains('izquierda')) {
      return Icons.turn_left;
    }
    if (texto.contains('derecha')) {
      return Icons.turn_right;
    }
    if (texto.contains('arriba') || texto.contains('sube')) {
      return Icons.stairs_rounded;
    }
    if (texto.contains('arriba') || texto.contains('abajo')) {
      return Icons.stairs;
    }
    if (texto.contains('llega') || texto.contains('destino')) {
      return Icons.flag;
    }
    if (texto.contains('vuelta')) {
      return Icons.turn_slight_left;
    }
    if (texto.contains('contin') || texto.contains('recto') || texto.contains('sigue')) {
      return Icons.straight;
    }
    return Icons.directions_walk;
  }

  String formatDistance(double meters) {
    if (meters.isInfinite || meters.isNaN) {
      return '—';
    }
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  void _showSnackBar(String message, {SnackBarAction? action}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showFullRoute() {
    final List<LatLng> points = _rutaORS?.ruta ?? _currentRoute?.coordenadas ?? const <LatLng>[];
    if (points.isEmpty) {
      return;
    }
    try {
      mapController.showFullRoute(points);
    } catch (e) {
      debugPrint('No se pudo mostrar la ruta completa: $e');
    }
  }

  void _fitSimpleRouteBounds() {
    if (_routeFrom == null || _routeTo == null) {
      return;
    }
    if (_isRouteCalculated) {
      return;
    }
    final points = <LatLng>[
      LatLng(_routeFrom!.latitud, _routeFrom!.longitud),
      LatLng(_routeTo!.latitud, _routeTo!.longitud),
    ];
    try {
      mapController.showFullRoute(points, padding: const EdgeInsets.all(60));
    } catch (e) {
      debugPrint('No se pudo ajustar preliminarmente la ruta: $e');
    }
  }
  void setSelectedProfile(OrsProfile profile) {
    if (_selectedProfile == profile) {
      return;
    }
    _selectedProfile = profile;
    notifyListeners();

    if (_routeFrom == null || _routeTo == null) {
      return;
    }

    if (_isCalculatingRoute) {
      return;
    }

    unawaited(_recalculateRouteForProfileChange());
  }

  bool _syncAvailableProfiles(List<String> allowedApiValues) {
    final List<OrsProfile> parsedProfiles = <OrsProfile>[];
    for (final String value in allowedApiValues) {
      final OrsProfile? profile = OrsProfileX.fromApiValue(value);
      if (profile != null && !parsedProfiles.contains(profile)) {
        parsedProfiles.add(profile);
      }
    }

    if (parsedProfiles.isEmpty) {
      return false;
    }

    final bool sameOrder = parsedProfiles.length == _availableProfiles.length &&
        Iterable<int>.generate(parsedProfiles.length)
            .every((int index) => _availableProfiles[index] == parsedProfiles[index]);

    if (sameOrder) {
      return false;
    }

    _availableProfiles
      ..clear()
      ..addAll(parsedProfiles);

    if (!_availableProfiles.contains(_selectedProfile)) {
      _selectedProfile = _availableProfiles.first;
    }

    return true;
  }

  Future<void> _recalculateRouteForProfileChange() async {
    if (_navigationState == NavigationState.navigating) {
      await finalizarNavegacion();
    }
    await calcularRuta();
  }


void handleFromLocationSelection(UbicacionModel? ubicacion) {
  if (ubicacion == null) {
    return;
  }
  
  setRouteFrom(ubicacion);
}

void activateMapSelectionForOrigin() {
  setMapSelectionMode(true);
}

  Future<void> startRoutePlanning(UbicacionModel destination) async {
    closeSearch();
    _resetNavigationGuidance();
    await _stopNavigationTracking();
    _routeTo = destination;
    _routeFrom = null;
    _isRouteCalculated = false;
    _navigationState = NavigationState.routePlanning;
    ubicacionSeleccionada = null;
    bottomSheetAlignment = const Alignment(0, 2);
    notifyListeners();

    final defaultOrigin = await _buildCurrentLocationOrigin();
    if (defaultOrigin != null) {
      setRouteFrom(defaultOrigin);
      _fitSimpleRouteBounds();
    }
  }

  Future<void> iniciarNavegacion() async {
    if (_navigationState == NavigationState.navigating) {
      return;
    }

    final trackingStarted = await _startNavigationTracking(distanceFilter: 2);
    if (!trackingStarted) {
      return;
    }

    if (_navigationSteps.isEmpty) {
      _applyNavigationStepsFromRoute(_rutaORS);
    }

    _currentStepDistanceMeters = double.infinity;
    _lastBroadcastedStepDistance = null;
    _hasArrived = false;
    _navigationState = NavigationState.navigating;
    setTrackUpEnabled(true);
  _updateTrackUpCamera(force: true);
    notifyListeners();
    print('Iniciando navegación...');

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      _updateUserLocation(LatLng(position.latitude, position.longitude));
      _handleNavigationLocationUpdate(position);
    } catch (_) {
      final Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _updateUserLocation(LatLng(lastKnown.latitude, lastKnown.longitude));
        _handleNavigationLocationUpdate(lastKnown);
      }
    }
  }

  Future<void> finalizarNavegacion() async {
    await _stopNavigationTracking();
    setTrackUpEnabled(false);
    try {
      mapController.rotate(0);
    } catch (e) {
      debugPrint('No se pudo restablecer la rotación del mapa al finalizar: $e');
    }
    _resetNavigationGuidance();

    if (_isRouteCalculated && _routeTo != null) {
      _navigationState = NavigationState.routePlanning;
    } else {
      _navigationState = NavigationState.normal;
      _routeFrom = null;
      _routeTo = null;
      _rutaORS = null;
      _currentRoute = null;
      _isRouteCalculated = false;
    }

    notifyListeners();
  }

  void cancelRoutePlanning() {
    unawaited(_stopNavigationTracking());
    setTrackUpEnabled(false);
    try {
      mapController.rotate(0);
    } catch (_) {
    }
    _navigationState = NavigationState.normal;
    _isRouteCalculated = false;
    _routeFrom = null;
    _routeTo = null;
    _rutaORS = null;
    _currentRoute = null;
    _showOriginSearchPanel = false;
    _resetNavigationGuidance();
    notifyListeners();
  }

  void setRouteFrom(UbicacionModel? ubicacion) {
    _routeFrom = ubicacion;
    notifyListeners();
    
    if (ubicacion != null && _routeTo != null) {
      _fitSimpleRouteBounds();
      calcularRuta();
    }
  }

  void toggleOriginSearchPanel(bool show) {
    _showOriginSearchPanel = show;
    notifyListeners();
  }

  Future<void> setCurrentLocationAsOrigin() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      
      final currentLocation = UbicacionModel(
        id: -1,
        nombre: 'Tu ubicación',
        tipo: 'ubicacion_actual',
        latitud: position.latitude,
        longitud: position.longitude,
        piso: 1,
      );
      
      setRouteFrom(currentLocation);
    } catch (e) {
      print('Error obteniendo ubicación actual: \$e');
    }
  }

  void setMapSelectionMode(bool enabled) {
    _mapSelectionMode = enabled;
    if (!enabled) {
      _selectedMapLocation = null;
    }
    notifyListeners();
  }

  void handleMapSelection(LatLng location) {
    if (_mapSelectionMode) {
      _selectedMapLocation = location;
      
      final selectedLocation = UbicacionModel(
        id: -2,
        nombre: 'Ubicación seleccionada',
        tipo: 'ubicacion_seleccionada',
        latitud: location.latitude,
        longitud: location.longitude,
        piso: 1,
      );
      
      setRouteFrom(selectedLocation);
      setMapSelectionMode(false);
    } else {
      _selectLocationFromMap(location);
    }
  }

  void _selectLocationFromMap(LatLng location) {
    const double radioBusqueda = 0.0005; 
    
    UbicacionModel? ubicacionCercana;
    double distanciaMinima = double.infinity;
    
    for (final ubicacion in ubicaciones) {
      final distancia = _calcularDistancia(
        location.latitude, location.longitude,
        ubicacion.latitud, ubicacion.longitud
      );
      
      if (distancia < radioBusqueda && distancia < distanciaMinima) {
        distanciaMinima = distancia;
        ubicacionCercana = ubicacion;
      }
    }
    
    if (ubicacionCercana != null) {
      buscarUbicacion(ubicacionCercana);
    } else {
      final ubicacionPersonalizada = UbicacionModel(
        id: -1,
        nombre: 'Ubicación personalizada',
        tipo: 'personalizada',
        latitud: location.latitude,
        longitud: location.longitude,
        piso: 1,
      );
      
      ubicacionSeleccionada = ubicacionPersonalizada;
      mapController.move(location, 17);
      bottomSheetAlignment = const Alignment(0, 0.6);
      _mostrarPanelBusqueda = false;
      notifyListeners();
    }
  }

  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    final deltaLat = lat1 - lat2;
    final deltaLon = lon1 - lon2;
    return (deltaLat * deltaLat + deltaLon * deltaLon);
  }

  @override
  void dispose() {
    _isControllerMounted = false;
    _navigationSubscription?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}

class _RouteMatchResult {
  const _RouteMatchResult({
    required this.projection,
    required this.segmentIndex,
    required this.segmentFraction,
  });

  final LatLng projection;
  final int segmentIndex;
  final double segmentFraction;
}

class _ProjectionResult {
  const _ProjectionResult({
    required this.point,
    required this.distance,
    required this.t,
  });

  final LatLng point;
  final double distance;
  final double t;
}
