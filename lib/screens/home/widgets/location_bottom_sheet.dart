import 'package:flutter/material.dart';

import 'package:unisonmap/models/ubicacion_model.dart';

class LocationBottomSheet extends StatelessWidget {
  final UbicacionModel ubicacionSeleccionada;
  final Alignment bottomSheetAlignment;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function() onShowDirections;
  final Function() onTapToExpand; 

  const LocationBottomSheet({
    super.key,
    required this.ubicacionSeleccionada,
    required this.bottomSheetAlignment,
    required this.onDragUpdate,
    required this.onShowDirections,
    required this.onTapToExpand,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedAlign(
      alignment: bottomSheetAlignment,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onVerticalDragUpdate: onDragUpdate,
        child: Container(
          height: screenHeight * 0.35,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 6)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ubicacionSeleccionada.nombre,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (ubicacionSeleccionada.tipo.isNotEmpty)
                Text("Departamento: ${ubicacionSeleccionada.tipo}"),
              const SizedBox(height: 12),
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Text(
                  "Aquí irá la imagen",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    tooltip: 'Compartir',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onShowDirections,
                    icon: const Icon(Icons.directions_walk),
                    label: const Text("Indicaciones"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}