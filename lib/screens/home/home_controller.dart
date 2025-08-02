import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/ubicacion_service.dart';
import '../../models/ubicacion_model.dart';
import '../../data/services/ors_service.dart';
import '../../models/ruta_ors_model.dart' as ors_model;
import '../../models/route_model.dart' as route_model;

enum NavigationState {
  normal,
  routePlanning,
  navigating
}

enum TransportType {
  walking,
  wheelchair,
  motorcycle,
  car
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

  final double bottomSheetMaxHeightFraction = 0.4;
  Alignment bottomSheetAlignment = const Alignment(0, 2); 

  late BuildContext context;

  NavigationState _navigationState = NavigationState.normal;
  NavigationState get navigationState => _navigationState;
  
  TransportType _selectedTransport = TransportType.walking;
String get selectedTransport {
  return _selectedTransport.toString().split('.').last;
}
  
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
  
  ors_model.RutaORS? _rutaORS;
  ors_model.RutaORS? get rutaORS => _rutaORS;

  bool _isCalculatingRoute = false;
  bool get isCalculatingRoute => _isCalculatingRoute;

  bool _isRouteCalculated = false;
  bool get isRouteCalculated => _isRouteCalculated;

  Future<void> init(BuildContext context) async {
    this.context = context;
    
    searchFocusNode.addListener(() {
      updateSearchPanelVisibility();
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

    _isCalculatingRoute = true;
    notifyListeners();

    try {
      print('Intentando obtener ruta ORS desde \${routeFrom!.nombre} hasta \${routeTo!.nombre}');
      
      final rutaORS = await _orsService.obtenerRutaReal(
        routeFrom!.id,
        routeTo!.id,
      );
      
      if (rutaORS != null) {
        print('Ruta ORS obtenida exitosamente');
        _rutaORS = rutaORS;
        _currentRoute = null; 
        
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
    
    _rutaORS = ors_model.RutaORS(
      ruta: directRoute,
      distanciaM: distanceInMeters.round(),
      duracionS: timeInMinutes * 60,
      origen: ors_model.UbicacionInfo(
        id: routeFrom!.id,
        nombre: routeFrom!.nombre,
        lat: routeFrom!.latitud,
        lng: routeFrom!.longitud,
      ),
      destino: ors_model.UbicacionInfo(
        id: routeTo!.id,
        nombre: routeTo!.nombre,
        lat: routeTo!.latitud,
        lng: routeTo!.longitud,
      ),
    );
    
    _currentRoute = null; 
    _distance = _rutaORS!.distanciaFormateada;
    _timeEstimate = _rutaORS!.tiempoFormateado;
    
    _adjustMapBounds(directRoute);
    
    _isRouteCalculated = true;
    
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
      ubicacionSeleccionada = ubicacionEncontrada;
      mapController.move(
        LatLng(ubicacionEncontrada.latitud, ubicacionEncontrada.longitud),
        17,
      );
      searchController.text = ubicacionEncontrada.nombre;
      bottomSheetAlignment = const Alignment(0, 1);
      _mostrarPanelBusqueda = false;
      guardarEnHistorial(ubicacionEncontrada.nombre);
      notifyListeners();
    }
  }


double getBottomSheetCurrentHeight(double screenHeight) {
  if (ubicacionSeleccionada == null) return 0;
  
  final sheetHeight = screenHeight * 0.35; 
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
    _mostrarPanelBusqueda = searchFocusNode.hasFocus || searchController.text.isNotEmpty;
    notifyListeners();
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

  Future<void> centrarEnUbicacionActual() async {
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
      mapController.move(LatLng(position.latitude, position.longitude), 17);
      
      ubicacionSeleccionada = null;
      bottomSheetAlignment = const Alignment(0, 2);
      notifyListeners();
    } catch (e) {
      print('Error obteniendo ubicación: \$e');
    }
  }

void setTransportType(String transport) {
  switch (transport) {
    case 'walking':
      _selectedTransport = TransportType.walking;
      break;
    case 'wheelchair':
      _selectedTransport = TransportType.wheelchair;
      break;
    default:
      _selectedTransport = TransportType.walking;
  }
  notifyListeners();
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

  void startRoutePlanning(UbicacionModel destination) {
    _routeTo = destination;
    _routeFrom = null; 
    _isRouteCalculated = false; 
    _navigationState = NavigationState.routePlanning;
    ubicacionSeleccionada = null;
    bottomSheetAlignment = const Alignment(0, 2);
    notifyListeners();
  }

  void iniciarNavegacion() {
    _navigationState = NavigationState.navigating;
    notifyListeners();
    print('Iniciando navegación...');
  }

  void cancelRoutePlanning() {
    _navigationState = NavigationState.normal;
    _isRouteCalculated = false;
    _routeFrom = null;
    _routeTo = null;
    _rutaORS = null;
    _currentRoute = null;
    _showOriginSearchPanel = false;
    notifyListeners();
  }

  void setRouteFrom(UbicacionModel? ubicacion) {
    _routeFrom = ubicacion;
    notifyListeners();
    
    if (ubicacion != null && _routeTo != null) {
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
        nombre: 'Ubicación actual',
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
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}
