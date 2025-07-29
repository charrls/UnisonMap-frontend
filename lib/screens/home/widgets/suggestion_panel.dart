import 'package:flutter/material.dart';

import 'package:unisonmap/models/ubicacion_model.dart';

class SuggestionPanel extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> historialBusquedas;
  final List<UbicacionModel> sugerencias;
  final Function(String) onSuggestionTap;

  const SuggestionPanel({
    super.key,
    required this.searchController,
    required this.historialBusquedas,
    required this.sugerencias,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.white,
        constraints: const BoxConstraints(maxHeight: 300), // Aumentar altura máxima
        child: searchController.text.isEmpty
            ? _buildHistorialSection()
            : _buildSugerenciasSection(),
      ),
    );
  }

  Widget _buildHistorialSection() {
    if (historialBusquedas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "Sin búsquedas recientes",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            "Búsquedas recientes",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: historialBusquedas.length,
            itemBuilder: (context, index) {
              final texto = historialBusquedas[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(texto),
                onTap: () => onSuggestionTap(texto),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSugerenciasSection() {
    if (sugerencias.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "No se encontró ninguna coincidencia",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            "Sugerencias (${sugerencias.length})",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sugerencias.length,
            itemBuilder: (context, index) {
              final ubicacion = sugerencias[index];
              return ListTile(
                leading: Icon(
                  _getIconForTipo(ubicacion.tipo),
                  color: Colors.blue,
                ),
                title: Text(ubicacion.nombre),
                subtitle: ubicacion.tipo.isNotEmpty 
                    ? Text(ubicacion.tipo)
                    : null,
                onTap: () => onSuggestionTap(ubicacion.nombre),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'edificio':
      case 'building':
        return Icons.business;
      case 'aula':
      case 'salon':
        return Icons.class_;
      case 'laboratorio':
        return Icons.science;
      case 'oficina':
        return Icons.work;
      case 'biblioteca':
        return Icons.library_books;
      case 'cafeteria':
      case 'comedor':
        return Icons.restaurant;
      case 'baño':
      case 'sanitario':
        return Icons.wc;
      case 'estacionamiento':
        return Icons.local_parking;
      default:
        return Icons.place;
    }
  }
}