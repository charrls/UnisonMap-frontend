import 'package:flutter/material.dart';
import '../../../models/ubicacion_model.dart';
import '../widgets/transport_selector.dart';
import '../home_controller.dart';

///Sin uso actual

class RoutePanel extends StatelessWidget {
  final UbicacionModel? fromLocation;
  final UbicacionModel toLocation;
  final List<UbicacionModel> ubicaciones;
  final TransportType selectedTransport;
  final Function(UbicacionModel?) onFromChanged;
  final Function(TransportType) onTransportChanged;
  final Function() onNavigate;
  final Function() onCancel;
  final String distance;
  final String timeEstimate;

  const RoutePanel({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.ubicaciones,
    required this.selectedTransport,
    required this.onFromChanged,
    required this.onTransportChanged,
    required this.onNavigate,
    required this.onCancel,
    required this.distance,
    required this.timeEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Parte superior (selectores)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),)
            ],
          ),
          child: Column(
            children: [
              _buildOriginSelector(),
              const SizedBox(height: 12),
              _buildDestinationField(),
              const SizedBox(height: 16),
              TransportSelector(
                selectedTransport: selectedTransport,
                onTransportSelected: onTransportChanged,
              ),
            ],
          ),
        ),

        // Parte inferior (información y acciones)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildRouteInfo(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOriginSelector() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Desde',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.search),
      ),
      onTap: () {
        // Mostrar el panel de sugerencias especial para origen
      },
    );
  }

  Widget _buildDestinationField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Hasta',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      readOnly: true,
      initialValue: toLocation.nombre,
    );
  }

  Widget _buildRouteInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.directions_walk),
            const SizedBox(width: 4),
            Text('$distance m'),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 4),
            Text('$timeEstimate min'),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: onNavigate,
            child: const Text('Iniciar navegación'),
          ),
        ),
      ],
    );
  }
}