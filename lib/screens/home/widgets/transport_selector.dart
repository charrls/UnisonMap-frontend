import 'package:flutter/material.dart';
import '../home_controller.dart';


class TransportSelector extends StatelessWidget {
  final TransportType selectedTransport;
  final Function(TransportType) onTransportSelected;

  const TransportSelector({
    super.key,
    required this.selectedTransport,
    required this.onTransportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(Icons.directions_walk,
              color: selectedTransport == TransportType.walking 
                  ? Colors.blue 
                  : Colors.grey),
          onPressed: () => onTransportSelected(TransportType.walking),
          tooltip: 'Caminando',
        ),
        IconButton(
          icon: Icon(Icons.accessible,
              color: selectedTransport == TransportType.wheelchair 
                  ? Colors.blue 
                  : Colors.grey),
          onPressed: () => onTransportSelected(TransportType.wheelchair),
          tooltip: 'Accesible',
        ),
        IconButton(
          icon: Icon(Icons.motorcycle,
              color: selectedTransport == TransportType.motorcycle 
                  ? Colors.blue 
                  : Colors.grey),
          onPressed: () => onTransportSelected(TransportType.motorcycle),
          tooltip: 'Motocicleta',
        ),
        IconButton(
          icon: Icon(Icons.directions_car,
              color: selectedTransport == TransportType.car 
                  ? Colors.blue 
                  : Colors.grey),
          onPressed: () => onTransportSelected(TransportType.car),
          tooltip: 'Automóvil',
        ),
      ],
    );
  }
}