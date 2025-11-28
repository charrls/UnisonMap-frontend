import 'package:flutter/material.dart';
import 'home_controller.dart';
import 'widgets/search_bar.dart';
import 'widgets/location_bottom_sheet.dart';
import 'widgets/map_view.dart';
import 'widgets/floating_buttons.dart';
import 'widgets/map_selection_overlay.dart';
import 'widgets/route_selector_panel.dart';
import 'widgets/route_info_panel.dart';
import 'widgets/search_overlay_widget.dart';
import 'widgets/navigation_instruction_panel.dart';
import 'widgets/navigation_top_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  double _routePanelHeight = 0.0;
  double _navPanelHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.init(context);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
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
                MapView(
                  controller: _controller.mapController,
                  ubicacionSeleccionada: _controller.ubicacionSeleccionada,
                  onMapTap: (position, latLng) => _controller.handleMapSelection(latLng),
                  showRoute: _controller.navigationState != NavigationState.normal,
                  selectionMode: _controller.mapSelectionMode,
                  selectedLocation: _controller.selectedMapLocation,
                  userLocation: _controller.userLocation,
                  navigationState: _controller.navigationState,
                  routeFrom: _controller.routeFrom,
                  routeTo: _controller.routeTo,
                  currentRoute: _controller.currentRoute,
                  rutaORS: _controller.rutaORS,
                  focusedStepMarker: _controller.focusedStepMarker,
                  gesturesEnabled: true,
                  trackUpEnabled: _controller.trackUpEnabled,
                  pendingRoutePolyline: _controller.pendingRoutePolyline,
                ),
                ..._buildComponentsByState(),
              ],
            ),
    );
  }

  double _buttonsBottomPadding() {
    final double screenHeight = MediaQuery.of(context).size.height;
    switch (_controller.navigationState) {
      case NavigationState.normal:
        final double bsHeight = _controller.getBottomSheetCurrentHeight(screenHeight);
        return bsHeight > 0 ? bsHeight + 16 : 16;
      case NavigationState.routePlanning:
        final double h = _routePanelHeight > 0 ? _routePanelHeight : 160;
        return h + 16;
      case NavigationState.navigating:
        final double estimatedPanel = (_controller.hasArrived ? 0.28 : 0.36) * screenHeight;
        final double h = _navPanelHeight > 0 ? _navPanelHeight : estimatedPanel;
        return h + 16;
    }
  }

  List<Widget> _buildComponentsByState() {
    final components = <Widget>[];

    if (_controller.mapSelectionMode) {
      components.add(
        MapSelectionOverlay(
          onCancel: () {
            _controller.setMapSelectionMode(false);
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

    // Estado: vista normal (sin planificación ni navegación)
    if (_controller.navigationState == NavigationState.normal) {
      const double searchBarTop = 60;
      const double overlayTopPadding = searchBarTop + 72;

      components.add(
        SearchOverlayWidget(
          isVisible: _controller.isSearching,
          controller: _controller,
          onClose: _controller.closeSearch,
          onSuggestionTap: _controller.buscarUbicacion,
          topPadding: overlayTopPadding,
        ),
      );

      components.add(
        Positioned(
          top: searchBarTop,
          left: 16,
          right: 16,
          child: MapSearchBar(
            controller: _controller,
            isSearching: _controller.isSearching,
            onCancelSearch: _controller.closeSearch,
          ),
        ),
      );

      if (_controller.ubicacionSeleccionada != null && !_controller.isSearching) {
        components.add(
          LocationBottomSheet(
            ubicacionSeleccionada: _controller.ubicacionSeleccionada!,
            bottomSheetAlignment: _controller.bottomSheetAlignment,
            onDragUpdate: _controller.handleBottomSheetDrag,
            onTapToExpand: _controller.expandBottomSheet,
            onShowDirections: () {
              _controller.startRoutePlanning(_controller.ubicacionSeleccionada!);
            },
          ),
        );
      }

      if (!_controller.isSearching) {
        components.add(
          Align(
            alignment: Alignment.bottomRight,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(right: 16, bottom: _buttonsBottomPadding()),
                child: FloatingButtons(
                  buttons: <FloatingButtonConfig>[
                    FloatingButtonConfig(
                      icon: Icons.my_location,
                      tooltip: 'Centrar mapa en posición actual',
                      onPressed: _controller.centrarEnUbicacionActual,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    // Estado: planificación de ruta
    if (_controller.navigationState == NavigationState.routePlanning) {
      components.add(
        Positioned(
          top: 60,
          left: 16,
          right: 16,
          child: RouteSelectorPanel(
            fromLocation: _controller.routeFrom,
            toLocation: _controller.routeTo ?? _controller.ubicacionSeleccionada!,
            ubicaciones: _controller.ubicaciones,
            selectedProfile: _controller.selectedProfile,
            availableProfiles: _controller.availableProfiles,
            onFromChanged: _controller.handleFromLocationSelection,
            onUseCurrentLocation: () => _controller.setCurrentLocationAsOrigin(),
            onProfileChanged: _controller.setSelectedProfile,
          ),
        ),
      );

      components.add(
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _MeasureSize(
            onChange: (size) {
              if (mounted) setState(() => _routePanelHeight = size.height);
            },
            child: RouteInfoPanel(
              distance: _controller.distance,
              timeEstimate: _controller.timeEstimate,
              onNavigate: _controller.isRouteCalculated
                  ? () => _controller.iniciarNavegacion()
                  : () => _controller.calcularRuta(),
              onCancel: () => _controller.cancelRoutePlanning(),
              isCalculating: _controller.isCalculatingRoute,
              isORSRoute: _controller.rutaORS != null,
              isRouteCalculated: _controller.isRouteCalculated,
            ),
          ),
        ),
      );

      components.add(
        Align(
          alignment: Alignment.bottomRight,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(right: 16, bottom: _buttonsBottomPadding()),
              child: FloatingButtons(
                buttons: <FloatingButtonConfig>[
                  FloatingButtonConfig(
                    icon: Icons.my_location,
                    tooltip: 'Centrar mapa en posición actual',
                    onPressed: _controller.centrarEnUbicacionActual,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

  // Estado: navegación activa
  if (_controller.navigationState == NavigationState.navigating) {
      // Banner superior con la instrucción actual
      components.add(
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: NavigationTopBanner(
                key: ValueKey<int>(_controller.currentStepIndex ^ (_controller.hasArrived ? 9999 : 0)),
                currentStep: _controller.currentStep,
                distanceToCurrentStep: _controller.distanceToCurrentStep,
                hasArrived: _controller.hasArrived,
                descriptionBuilder: _controller.getStepDescription,
                iconBuilder: _controller.getStepIcon,
                distanceFormatter: _controller.formatDistance,
              ),
            ),
          ),
        ),
      );

      // Panel deslizable inferior (lista de pasos + terminar navegación) en modo compcto sin header
      components.add(
        NavigationInstructionPanel(
          steps: _controller.navigationSteps,
          focusedIndex: _controller.currentStepIndex,
          distanceToCurrentStep: _controller.distanceToCurrentStep,
          hasArrived: _controller.hasArrived,
          descriptionBuilder: _controller.getStepDescription,
          iconBuilder: _controller.getStepIcon,
          distanceFormatter: _controller.formatDistance,
          onStepTap: (int index) => _controller.rutaController.irAPaso(index),
          onFinish: () async => _controller.finalizarNavegacion(),
          hideCurrentStepHeader: true,
          remainingDistanceLabel: _controller.formattedRemainingDistance,
          remainingDurationLabel: _controller.formattedRemainingDuration,
          etaLabel: _controller.formattedEta,
          onCloseNavigation: () async => _controller.finalizarNavegacion(),
          onExtentChanged: (double extent) {
            final double screenHeight = MediaQuery.of(context).size.height;
            final double newHeight = (extent.clamp(0.0, 1.0)) * screenHeight;
            if ((newHeight - _navPanelHeight).abs() > 0.5 && mounted) {
              setState(() => _navPanelHeight = newHeight);
            }
          },
        ),
      );

      // Botones flotantes (GPS + Ruta completa)
      components.add(
        Align(
          alignment: Alignment.bottomRight,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(right: 16, bottom: _buttonsBottomPadding()),
              child: FloatingButtons(
                buttons: <FloatingButtonConfig>[
                  FloatingButtonConfig(
                    icon: Icons.my_location,
                    tooltip: 'Centrar mapa en posición actual',
                    onPressed: _controller.centrarEnUbicacionActual,
                  ),
                  FloatingButtonConfig(
                    icon: Icons.route,
                    tooltip: 'Mostrar ruta completa',
                    onPressed: _controller.showFullRoute,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return components;
  }
}

class _MeasureSize extends StatefulWidget {
  const _MeasureSize({required this.onChange, required this.child});
  final ValueChanged<Size> onChange;
  final Widget child;

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  Size _oldSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.size;
      if (s != null && s != _oldSize) {
        _oldSize = s;
        widget.onChange(s);
      }
    });
    return KeyedSubtree(key: ValueKey<Object>(_oldSize), child: widget.child);
  }
}
 
