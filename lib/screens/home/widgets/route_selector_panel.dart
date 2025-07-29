// En lib/screens/home/widgets/route_selector_panel.dart
import 'package:flutter/material.dart';
import '../../../models/ubicacion_model.dart';
import 'transport_selector.dart'; 
import '../home_controller.dart'; 

class RouteSelectorPanel extends StatefulWidget {
  final UbicacionModel? fromLocation;
  final UbicacionModel toLocation;
  final List<UbicacionModel> ubicaciones;
  final String selectedTransport;
  final Function(UbicacionModel?) onFromChanged;
  final Function(String) onTransportChanged;

  const RouteSelectorPanel({
    super.key,
    this.fromLocation,
    required this.toLocation,
    required this.ubicaciones,
    required this.selectedTransport,
    required this.onFromChanged,
    required this.onTransportChanged,
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
    
    // Si ya hay una ubicación seleccionada, mostrarla en el campo
    if (widget.fromLocation != null) {
      _fromController.text = widget.fromLocation!.nombre;
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
      // Mostrar ubicaciones populares cuando no hay búsqueda
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
    _fromController.text = ubicacion.nombre;
    _fromFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    widget.onFromChanged(ubicacion);
  }

// En route_selector_panel.dart - AGREGAR estas funciones de conversión al final de _RouteSelectorPanelState:

TransportType _stringToTransportType(String transport) {
  switch (transport) {
    case 'walking':
      return TransportType.walking;
    case 'wheelchair':
      return TransportType.wheelchair;
    case 'motorcycle':
      return TransportType.motorcycle;
    case 'car':
      return TransportType.car;
    default:
      return TransportType.walking;
  }
}

String _transportTypeToString(TransportType transportType) {
  switch (transportType) {
    case TransportType.walking:
      return 'walking';
    case TransportType.wheelchair:
      return 'wheelchair';
    case TransportType.motorcycle:
      return 'motorcycle';
    case TransportType.car:
      return 'car';
  }
}

 @override
  Widget build(BuildContext context) {
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
                // Campo "Desde" - Buscador directo
                TextField(
                  controller: _fromController,
                  focusNode: _fromFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Desde',
                    hintText: 'Buscar ubicación de origen...',
                    prefixIcon: const Icon(Icons.my_location, color: Colors.green),
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
                
                const SizedBox(height: 16),
                
                // Campo "Hasta" - Solo lectura
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
                
                // REEMPLAZAR el DropdownButton por TransportSelector:
                TransportSelector(
                  selectedTransport: _stringToTransportType(widget.selectedTransport),
                  onTransportSelected: (transportType) {
                    widget.onTransportChanged(_transportTypeToString(transportType));
                  },
                ),

              ],
            ),
          ),
        ),
        
        // Panel de sugerencias (permanece igual)
        if (_showSuggestions)
          Material(
            elevation: 2,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Opciones especiales cuando no hay texto
                  if (_fromController.text.isEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.gps_fixed, color: Colors.blue),
                      title: const Text('Tu ubicación actual'),
                      onTap: () {
                        _fromController.text = 'Tu ubicación actual';
                        _fromFocusNode.unfocus();
                        setState(() {
                          _showSuggestions = false;
                        });
                        widget.onFromChanged(null);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.pin_drop, color: Colors.blue),
                      title: const Text('Seleccionar en el mapa'),
                      onTap: () {
                        _fromFocusNode.unfocus();
                        setState(() {
                          _showSuggestions = false;
                        });
                        widget.onFromChanged(null);
                      },
                    ),
                    const Divider(),
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
                  
                  // Lista de sugerencias
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
                    ...(_filteredSuggestions.map(
                      (ubicacion) => ListTile(
                        leading: _getIconForTipo(ubicacion.tipo),
                        title: Text(ubicacion.nombre),
                        subtitle: ubicacion.tipo.isNotEmpty 
                            ? Text(ubicacion.tipo)
                            : null,
                        onTap: () => _selectFromLocation(ubicacion),
                      ),
                    )),
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