import 'package:flutter/material.dart';

class FloatingButtonConfig {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const FloatingButtonConfig({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });
}

class FloatingButtons extends StatelessWidget {
  final List<FloatingButtonConfig> buttons;
  final double spacing;

  const FloatingButtons({
    super.key,
    required this.buttons,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = Theme.of(context).colorScheme.surface.withOpacity(0.9);
    final ShapeBorder shape = const CircleBorder(side: BorderSide(color: Colors.white, width: 1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < buttons.length; i++) ...<Widget>[
          _StyledFAB(
            icon: buttons[i].icon,
            tooltip: buttons[i].tooltip,
            onPressed: buttons[i].onPressed,
            background: background,
            shape: shape,
            heroTag: 'floating_btn_$i',
          ),
          if (i < buttons.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

class _StyledFAB extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;
  final Color background;
  final ShapeBorder shape;
  final String heroTag;

  const _StyledFAB({
    required this.icon,
    required this.onPressed,
    required this.background,
    required this.shape,
    required this.heroTag,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final Widget fab = FloatingActionButton(
      heroTag: heroTag,
      backgroundColor: background,
      elevation: 6,
      shape: shape,
      onPressed: onPressed,
      child: Icon(icon, color: Colors.black87),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: fab);
    }
    return fab;
  }
}