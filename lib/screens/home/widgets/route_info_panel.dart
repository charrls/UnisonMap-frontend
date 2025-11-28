import 'package:flutter/material.dart';

class RouteInfoPanel extends StatelessWidget {
  final String distance;
  final String timeEstimate;
  final Future<void> Function() onNavigate;
  final VoidCallback onCancel;
  final bool isCalculating;
  final bool isORSRoute; 
  final bool isRouteCalculated; 

  const RouteInfoPanel({
    super.key,
    required this.distance,
    required this.timeEstimate,
    required this.onNavigate,
    required this.onCancel,
    this.isCalculating = false,
    this.isORSRoute = false, 
    this.isRouteCalculated = false, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isORSRoute)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Ruta real optimizada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (isORSRoute) const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk),
                  const SizedBox(width: 4),
                  Text(distance),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 4),
                  Text(timeEstimate),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
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
                  onPressed: isCalculating
                      ? null
                      : () async {
                          await onNavigate();
                        },
                  child: isCalculating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isRouteCalculated ? 'Iniciar navegación' : 'Calcular ruta'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
