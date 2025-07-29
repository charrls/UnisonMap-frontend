import 'package:flutter/material.dart';

class FloatingButtons extends StatelessWidget {
  final bool bottomSheetVisible;
  final double bottomSheetCurrentHeight; 
  final VoidCallback onLocationPressed;

  const FloatingButtons({
    super.key,
    required this.bottomSheetVisible,
    required this.bottomSheetCurrentHeight,
    required this.onLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottomSheetVisible
          ? bottomSheetCurrentHeight + 16 
          : 16, 
      right: 16,
      child: FloatingActionButton(
        heroTag: 'gps',
        onPressed: onLocationPressed,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}