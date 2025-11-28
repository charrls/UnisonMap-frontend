import 'package:flutter/material.dart';
import '../../../models/ruta_ors_model.dart' as ors_model;

/// Banner superior que muestra la instrucción actual de navegación
class NavigationTopBanner extends StatelessWidget {
  const NavigationTopBanner({
    super.key,
    required this.currentStep,
    required this.distanceToCurrentStep,
    required this.hasArrived,
    required this.descriptionBuilder,
    required this.iconBuilder,
    required this.distanceFormatter,
  });

  final ors_model.RutaStep? currentStep;
  final double distanceToCurrentStep;
  final bool hasArrived;
  final String Function(ors_model.RutaStep) descriptionBuilder;
  final IconData Function(ors_model.RutaStep) iconBuilder;
  final String Function(double meters) distanceFormatter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (hasArrived) {
      return _buildArrival(theme);
    }

    if (currentStep == null) {
      return _buildPlaceholder(theme);
    }

    final String distanceLabel = distanceToCurrentStep.isFinite && distanceToCurrentStep > 1
        ? distanceFormatter(distanceToCurrentStep)
        : currentStep!.distanceM > 0
            ? distanceFormatter(currentStep!.distanceM.toDouble())
            : '—';
    final String durationLabel = _formatDuration(currentStep!.durationS);
    final IconData icon = iconBuilder(currentStep!);

    return _BaseContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(icon, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  descriptionBuilder(currentStep!),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: <Widget>[
                    if (distanceLabel != '—') _InfoChip(icon: Icons.social_distance, label: distanceLabel),
                    if (durationLabel.isNotEmpty) _InfoChip(icon: Icons.timer_outlined, label: durationLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrival(ThemeData theme) {
    return _BaseContainer(
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.flag, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Has llegado a tu destino',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Finaliza la navegación cuando quieras.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return _BaseContainer(
      child: Text(
        'Preparando instrucciones...',
        style: theme.textTheme.titleMedium,
      ),
    );
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final Duration d = Duration(seconds: seconds);
    final int m = d.inMinutes;
    final int s = d.inSeconds.remainder(60);
    if (m == 0) return '${s}s';
    if (s == 0) return '${m} min';
    return '${m} min ${s}s';
  }
}

class _BaseContainer extends StatelessWidget {
  const _BaseContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: child,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
