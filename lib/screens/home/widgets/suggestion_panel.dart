import 'package:flutter/material.dart';

import 'package:unisonmap/models/ubicacion_model.dart';

class SuggestionPanel extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> historialBusquedas;
  final List<UbicacionModel> sugerencias;
  final ValueChanged<dynamic> onSuggestionTap;
  final BorderRadius borderRadius;
  final double? maxHeight;
  final Color? backgroundColor;
  final ScrollPhysics? scrollPhysics;

  const SuggestionPanel({
    super.key,
    required this.searchController,
    required this.historialBusquedas,
    required this.sugerencias,
    required this.onSuggestionTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.maxHeight,
    this.backgroundColor,
    this.scrollPhysics,
  });

  @override
  Widget build(BuildContext context) {
  final panelColor = backgroundColor ?? Colors.white;

    return Material(
      elevation: 0,
      color: panelColor,
      borderRadius: borderRadius,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: searchController.text.isEmpty
            ? _buildHistorialSection(context)
            : _buildSugerenciasSection(context),
      ),
    );
  }

  Widget _buildHistorialSection(BuildContext context) {
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Búsquedas recientes',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            physics: scrollPhysics ?? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.zero,
            itemCount: historialBusquedas.length,
            itemBuilder: (context, index) {
              final texto = historialBusquedas[index];
              return ListTile(
                leading: Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(texto),
                onTap: () => onSuggestionTap(texto),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSugerenciasSection(BuildContext context) {
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
            'Sugerencias (${sugerencias.length})',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            physics: scrollPhysics ?? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.zero,
            itemCount: sugerencias.length,
            itemBuilder: (context, index) {
              final ubicacion = sugerencias[index];
              return ListTile(
                leading: Icon(
                  _getIconForTipo(ubicacion.tipo),
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(ubicacion.nombre),
                subtitle: ubicacion.tipo.isNotEmpty 
                    ? Text(ubicacion.tipo)
                    : null,
                onTap: () => onSuggestionTap(ubicacion),
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