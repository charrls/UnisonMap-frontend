import 'package:flutter/material.dart';
import '../../home/home_controller.dart';

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FloatingActionButton(
          heroTag: 'notificaciones',
          mini: true,
          onPressed: () {},
          child: const Icon(Icons.notifications),
          backgroundColor: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller.searchController,
            focusNode: controller.searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Buscar ubicación...',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              controller.actualizarSugerencias(value);
              controller.updateSearchPanelVisibility();
            },
            onTap: () {
              controller.updateSearchPanelVisibility();
            },
            onSubmitted: (value) {
              controller.buscarUbicacion(value);
            },
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          heroTag: 'config',
          mini: true,
          onPressed: () {},
          child: const Icon(Icons.settings, color: Colors.blueGrey),
          backgroundColor: Colors.white,
        ),
      ],
    );
  }
}