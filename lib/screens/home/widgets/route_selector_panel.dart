import 'package:flutter/material.dart';

import '../../../core/enums/ors_profile.dart';
import '../../../models/ubicacion_model.dart';
import 'transport_selector.dart';

class RouteSelectorPanel extends StatefulWidget {
  final UbicacionModel? fromLocation;
  final UbicacionModel toLocation;
  final List<UbicacionModel> ubicaciones;
  final OrsProfile selectedProfile;
  final List<OrsProfile> availableProfiles;
  final Function(UbicacionModel?) onFromChanged;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<OrsProfile> onProfileChanged;

  const RouteSelectorPanel({
    super.key,
    this.fromLocation,
    required this.toLocation,
    required this.ubicaciones,
    required this.selectedProfile,
    this.availableProfiles = kDefaultOrsProfiles,
    required this.onFromChanged,
    required this.onUseCurrentLocation,
    required this.onProfileChanged,
  });

  @override
  State<RouteSelectorPanel> createState() => _RouteSelectorPanelState();
}

class _RouteSelectorPanelState extends State<RouteSelectorPanel> {
  final TextEditingController _fromController = TextEditingController();
  final FocusNode _fromFocusNode = FocusNode();
  bool _showSuggestions = false;
  List<UbicacionModel> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _fromFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _fromFocusNode.hasFocus;
      });
      if (_fromFocusNode.hasFocus && _fromController.text.isEmpty) {
        _updateSuggestions('');
      }
    });
    
    if (widget.fromLocation != null) {
      final isCurrentLocation = widget.fromLocation!.tipo.toLowerCase() == 'ubicacion_actual';
      _fromController.text = isCurrentLocation ? 'Tu ubicación' : widget.fromLocation!.nombre;
    }
  }

  @override
  void didUpdateWidget(covariant RouteSelectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fromLocation != oldWidget.fromLocation) {
      if (widget.fromLocation != null) {
        final isCurrentLocation = widget.fromLocation!.tipo.toLowerCase() == 'ubicacion_actual';
        final displayName = isCurrentLocation ? 'Tu ubicación' : widget.fromLocation!.nombre;
        _fromController.value = TextEditingValue(
          text: displayName,
          selection: TextSelection.collapsed(offset: displayName.length),
        );
      } else if (!_fromFocusNode.hasFocus) {
        _fromController.clear();
      }
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _fromFocusNode.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      _filteredSuggestions = widget.ubicaciones.take(5).toList();
    } else {
      final queryLower = query.toLowerCase().trim();
      
      final exactMatches = <UbicacionModel>[];
      final startMatches = <UbicacionModel>[];
      final containsMatches = <UbicacionModel>[];
      
      for (final location in widget.ubicaciones) {
        final nameLower = location.nombre.toLowerCase();
        final typeLower = location.tipo.toLowerCase();
        
        if (nameLower == queryLower) {
          exactMatches.add(location);
        } else if (nameLower.startsWith(queryLower)) {
          startMatches.add(location);
        } else if (nameLower.contains(queryLower) || typeLower.contains(queryLower)) {
          containsMatches.add(location);
        }
      }
      
      _filteredSuggestions = [
        ...exactMatches,
        ...startMatches,
        ...containsMatches,
      ].take(8).toList();
    }
    setState(() {});
  }

  void _selectFromLocation(UbicacionModel ubicacion) {
    final isCurrentLocation = ubicacion.tipo.toLowerCase() == 'ubicacion_actual';
    _fromController.text = isCurrentLocation ? 'Tu ubicación' : ubicacion.nombre;
    _fromFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    widget.onFromChanged(ubicacion);
  }

 @override
  Widget build(BuildContext context) {
      final normalizedText = _fromController.text.trim().toLowerCase();
      final bool isCurrentLocationActive = normalizedText == 'tu ubicación';

    return Column(
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    TextField(
                      controller: _fromController,
                      focusNode: _fromFocusNode,
                      style: TextStyle(
                        color: isCurrentLocationActive ? Colors.blue : Colors.black87,
                        fontWeight: isCurrentLocationActive ? FontWeight.bold : FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Desde',
                        hintText: 'Buscar ubicación de origen...',
                        prefixIcon: Icon(
                          Icons.my_location,
                          color: isCurrentLocationActive ? Colors.blue : Colors.green,
                        ),
                        suffixIcon: _fromController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _fromController.clear();
                                  widget.onFromChanged(null);
                                  _updateSuggestions('');

                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), 
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      onChanged: (value) {
                        _updateSuggestions(value);
                        if (value.isEmpty) {
                          widget.onFromChanged(null);
                        }
                      },
                      onSubmitted: (value) {
                        if (_filteredSuggestions.isNotEmpty) {
                          _selectFromLocation(_filteredSuggestions.first);
                        }
                      },
                    ),

                    if (_showSuggestions)
                      Material(
                        elevation: 2,
                        color: Colors.white,        
                        surfaceTintColor: Colors.transparent,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            children: [
                              if (_fromController.text.isEmpty) ...[
                                ListTile(
                                  leading: const Icon(Icons.gps_fixed, color: Colors.blue),
                                  title: const Text(
                                    'Tu ubicación',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () {
                                    _fromController.text = 'Tu ubicación';
                                    _fromFocusNode.unfocus();
                                    setState(() => _showSuggestions = false);
                                    widget.onUseCurrentLocation();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.pin_drop, color: Colors.blue),
                                  title: const Text('Seleccionar en el mapa'),
                                  onTap: () {
                                    _fromFocusNode.unfocus();
                                    setState(() => _showSuggestions = false);
                                    widget.onFromChanged(null);
                                  },
                                ),
                                const Divider(height: 1),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    'Ubicaciones sugeridas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],

                              if (_filteredSuggestions.isEmpty && _fromController.text.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No se encontraron ubicaciones',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else
                                ..._filteredSuggestions.map(
                                  (ubicacion) => ListTile(
                                    leading: _getIconForTipo(ubicacion.tipo),
                                    title: Text(ubicacion.nombre),
                                    subtitle: ubicacion.tipo.isNotEmpty ? Text(ubicacion.tipo) : null,
                                    onTap: () => _selectFromLocation(ubicacion),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Hasta',
                  hintText: widget.toLocation.nombre,
                  prefixIcon: const Icon(Icons.place, color: Colors.red),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  fillColor: Colors.grey[100],
                  filled: true,
                ),
              ),

              const SizedBox(height: 16),

              TransportSelector(
                profiles: widget.availableProfiles,
                selectedProfile: widget.selectedProfile,
                onProfileSelected: widget.onProfileChanged,
              ),


              ],
            ),
          ),
        ),
        
      ],
    );
  }

  Icon _getIconForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'edificio':
        return const Icon(Icons.business, color: Colors.grey);
      case 'aula':
        return const Icon(Icons.class_, color: Colors.grey);
      case 'laboratorio':
        return const Icon(Icons.science, color: Colors.grey);
      case 'oficina':
        return const Icon(Icons.work, color: Colors.grey);
      case 'cafeteria':
        return const Icon(Icons.restaurant, color: Colors.grey);
      case 'baño':
        return const Icon(Icons.wc, color: Colors.grey);
      default:
        return const Icon(Icons.place, color: Colors.grey);
    }
  }
}