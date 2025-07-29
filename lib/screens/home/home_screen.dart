import 'package:flutter/material.dart';
import 'home_controller.dart';
import 'widgets/search_bar.dart';
import 'widgets/suggestion_panel.dart';
import 'widgets/location_bottom_sheet.dart';
import 'widgets/map_view.dart';
import 'widgets/floating_buttons.dart';
import 'widgets/map_selection_overlay.dart';
import 'widgets/route_selector_panel.dart';
import 'widgets/route_info_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.init(context);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Mapa base
                MapView(
                  controller: _controller.mapController,
                  ubicacionSeleccionada: _controller.ubicacionSeleccionada,
                  onMapTap: (position, latLng) => _controller.handleMapSelection(latLng),
                  showRoute: _controller.navigationState != NavigationState.normal,
                  selectionMode: _controller.mapSelectionMode,
                  selectedLocation: _controller.selectedMapLocation,
                  navigationState: _controller.navigationState,
                  routeFrom: _controller.routeFrom,
                  routeTo: _controller.routeTo,
                  currentRoute: _controller.currentRoute,
                  rutaORS: _controller.rutaORS,
                ),
                // Componentes según el estado
                ..._buildComponentsByState(),
              ],
            ),
    );
  }

  List<Widget> _buildComponentsByState() {
    final components = <Widget>[];

    // Modo selección de mapa
    if (_controller.mapSelectionMode) {
      components.add(
        MapSelectionOverlay(
          onCancel: () {
            _controller.setMapSelectionMode(false);
            // Solo mostrar el panel de origen si estamos en modo de planificación de rutas
            if (_controller.navigationState == NavigationState.routePlanning) {
              _controller.toggleOriginSearchPanel(true);
            }
          },
          onConfirm: () {
            if (_controller.selectedMapLocation != null) {
              _controller.handleMapSelection(_controller.selectedMapLocation!);
            }
          },
        ),
      );
    }

    if (_controller.navigationState == NavigationState.normal) {
      components.addAll([
        Positioned(
          top: 60,
          left: 16,
          right: 16,
          child: MapSearchBar(controller: _controller),
        ),
        if (_controller.mostrarPanelBusqueda)
          Positioned(
            top: 110,
            left: 16,
            right: 16,
            child: SuggestionPanel(
              searchController: _controller.searchController,
              historialBusquedas: _controller.historialBusquedas,
              sugerencias: _controller.sugerencias,
              onSuggestionTap: (ubicacion) => _controller.buscarUbicacion(ubicacion),
            ),
          ),
        if (_controller.ubicacionSeleccionada != null)
        LocationBottomSheet(
          ubicacionSeleccionada: _controller.ubicacionSeleccionada!,
          bottomSheetAlignment: _controller.bottomSheetAlignment,
          onDragUpdate: _controller.handleBottomSheetDrag,
          onTapToExpand: _controller.expandBottomSheet,
          onShowDirections: () {
            _controller.startRoutePlanning(_controller.ubicacionSeleccionada!);
          },
        ),
        FloatingButtons(
          bottomSheetVisible: _controller.ubicacionSeleccionada != null,
          bottomSheetCurrentHeight: _controller.getBottomSheetCurrentHeight(MediaQuery.of(context).size.height), // Cambiar esta línea
          onLocationPressed: _controller.centrarEnUbicacionActual,
        ),
      ]);
    }

// En lib/screens/home/home_screen.dart
// ELIMINAR todo el bloque de OriginSearchPanel:

if (_controller.navigationState == NavigationState.routePlanning) {
  components.addAll([
    Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: RouteSelectorPanel(
        fromLocation: _controller.routeFrom,
        toLocation: _controller.routeTo ?? _controller.ubicacionSeleccionada!,
        ubicaciones: _controller.ubicaciones,
        selectedTransport: _controller.selectedTransport,
        onFromChanged: _controller.handleFromLocationSelection, // Nuevo método
        onTransportChanged: _controller.setTransportType,
      ),
    ),
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: RouteInfoPanel(
        distance: _controller.distance,
        timeEstimate: _controller.timeEstimate,
        onNavigate: _controller.isRouteCalculated
            ? () => _controller.iniciarNavegacion()
            : () => _controller.calcularRuta(),
        onCancel: () {
          _controller.cancelRoutePlanning();
        },
        isCalculating: _controller.isCalculatingRoute,
        isORSRoute: _controller.rutaORS != null,
        isRouteCalculated: _controller.isRouteCalculated,
      ),
    ),
    // YA NO NECESITAS el OriginSearchPanel
  ]);
}

    return components;
  }
}
