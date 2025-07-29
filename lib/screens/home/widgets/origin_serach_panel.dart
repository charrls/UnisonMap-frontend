import 'package:flutter/material.dart';
import '../../../models/ubicacion_model.dart';

class OriginSearchPanel extends StatefulWidget {
  final Function() onUseCurrentLocation;
  final Function() onSelectFromMap;
  final List<UbicacionModel> allLocations; 
  final Function(UbicacionModel) onSelectSuggestion;
  final Function(String) onSearchChanged; 

  const OriginSearchPanel({
    super.key,
    required this.onUseCurrentLocation,
    required this.onSelectFromMap,
    required this.allLocations,
    required this.onSelectSuggestion,
    required this.onSearchChanged,
  });

  @override
  State<OriginSearchPanel> createState() => _OriginSearchPanelState();
}

class _OriginSearchPanelState extends State<OriginSearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<UbicacionModel> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus(); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      _filteredSuggestions = [];
    } else {
      final queryLower = query.toLowerCase().trim();
      
      // Filtrar ubicaciones basado en la consulta
      final exactMatches = <UbicacionModel>[];
      final startMatches = <UbicacionModel>[];
      final containsMatches = <UbicacionModel>[];
      
      for (final location in widget.allLocations) {
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
      ].take(12).toList(); 
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.white,
        constraints: const BoxConstraints(maxHeight: 350),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Campo de búsqueda
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar ubicación de origen...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _updateSuggestions('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  _updateSuggestions(value);
                },
                onSubmitted: (value) {
                  // Si hay sugerencias exactas, seleccionar la primera
                  if (_filteredSuggestions.isNotEmpty) {
                    widget.onSelectSuggestion(_filteredSuggestions.first);
                  }
                },
              ),
            ),
            const Divider(height: 1),
            // Lista de opciones y sugerencias
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Opciones especiales solo si no hay búsqueda activa
                  if (_searchController.text.isEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.gps_fixed, color: Colors.blue),
                      title: const Text('Tu ubicación actual'),
                      onTap: widget.onUseCurrentLocation,
                    ),
                    ListTile(
                      leading: const Icon(Icons.pin_drop, color: Colors.blue),
                      title: const Text('Seleccionar en el mapa'),
                      onTap: widget.onSelectFromMap,
                    ),
                    const Divider(height: 1),
                    // Mostrar últimas ubicaciones o sugerencias populares
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
                    // Mostrar algunas ubicaciones populares
                    ...widget.allLocations.take(5).map(
                      (ubicacion) => ListTile(
                        leading: _getIconForTipo(ubicacion.tipo),
                        title: Text(ubicacion.nombre),
                        subtitle: ubicacion.tipo.isNotEmpty 
                            ? Text(ubicacion.tipo)
                            : null,
                        onTap: () => widget.onSelectSuggestion(ubicacion),
                      ),
                    ),
                  ] else ...[
                    // Mostrar resultados de búsqueda
                    if (_filteredSuggestions.isEmpty)
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
                          onTap: () => widget.onSelectSuggestion(ubicacion),
                        ),
                      )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getIconForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'edificio':
      case 'building':
        return const Icon(Icons.business, color: Colors.grey);
      case 'aula':
      case 'salon':
        return const Icon(Icons.class_, color: Colors.grey);
      case 'laboratorio':
        return const Icon(Icons.science, color: Colors.grey);
      case 'oficina':
        return const Icon(Icons.work, color: Colors.grey);
      case 'biblioteca':
        return const Icon(Icons.library_books, color: Colors.grey);
      case 'cafeteria':
      case 'comedor':
        return const Icon(Icons.restaurant, color: Colors.grey);
      case 'baño':
      case 'sanitario':
        return const Icon(Icons.wc, color: Colors.grey);
      case 'estacionamiento':
        return const Icon(Icons.local_parking, color: Colors.grey);
      default:
        return const Icon(Icons.place, color: Colors.grey);
    }
  }
}
