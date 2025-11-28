import 'package:flutter/material.dart';
import '../../../models/ruta_ors_model.dart' as ors_model;

/// Panel de navegación inferior.
class NavigationInstructionPanel extends StatefulWidget {
  const NavigationInstructionPanel({
    super.key,
    required this.steps,
    required this.focusedIndex,
    required this.distanceToCurrentStep,
    required this.hasArrived,
    required this.descriptionBuilder,
    required this.iconBuilder,
    required this.distanceFormatter,
    required this.onStepTap,
    required this.onFinish,
    this.onExtentChanged,
    this.hideCurrentStepHeader = false,
    this.onCloseNavigation,
    this.remainingDistanceLabel,
    this.remainingDurationLabel,
    this.etaLabel,
  });

  final List<ors_model.RutaStep> steps;
  final int focusedIndex;
  final double distanceToCurrentStep;
  final bool hasArrived;
  final String Function(ors_model.RutaStep) descriptionBuilder;
  final IconData Function(ors_model.RutaStep) iconBuilder;
  final String Function(double meters) distanceFormatter;
  final ValueChanged<int> onStepTap;
  final Future<void> Function() onFinish;
  final ValueChanged<double>? onExtentChanged;
  final bool hideCurrentStepHeader;
  final VoidCallback? onCloseNavigation;
  final String? remainingDistanceLabel;
  final String? remainingDurationLabel;
  final String? etaLabel;

  @override
  State<NavigationInstructionPanel> createState() => _NavigationInstructionPanelState();
}

class _NavigationInstructionPanelState extends State<NavigationInstructionPanel> {
  double _lastExtent = 0; 
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  bool get _isExpanded => _lastExtent > (_minSheetSize() + 0.02);

  double _minSheetSize() {
    return widget.hideCurrentStepHeader
        ? (widget.hasArrived ? 0.117 : 0.117)
        : (widget.hasArrived ? 0.24 : 0.3);
  }

  double _initialSheetSize() {
    return widget.hideCurrentStepHeader
        ? (widget.hasArrived ? 0.12 : 0.12)
        : (widget.hasArrived ? 0.28 : 0.36);
  }

  void _handleExtent(double extent) {
    if ((extent - _lastExtent).abs() > 0.001) {
      setState(() => _lastExtent = extent);
    }
    widget.onExtentChanged?.call(extent);
  }

  void _toggleExpand() {
    final double minSize = _minSheetSize();
    final double target = _isExpanded ? minSize : 0.4; 
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasSteps = widget.steps.isNotEmpty;
    final int safeIndex = hasSteps ? widget.focusedIndex.clamp(0, widget.steps.length - 1) : 0;
    final ors_model.RutaStep? currentStep = hasSteps ? widget.steps[safeIndex] : null;
    final double minSheetSize = _minSheetSize();
    final double initialSheetSize = _initialSheetSize();

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (DraggableScrollableNotification n) {
        _handleExtent(n.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: initialSheetSize,
        minChildSize: minSheetSize,
        maxChildSize: 0.4,
        snap: true,
        builder: (BuildContext context, ScrollController scrollController) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_lastExtent == 0) {
              _handleExtent(initialSheetSize);
            }
          });
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (!widget.hideCurrentStepHeader) ...<Widget>[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: widget.hasArrived
                          ? _ArrivalCard(theme: theme)
                          : _CurrentStepCard(
                              theme: theme,
                              step: currentStep,
                              descriptionBuilder: widget.descriptionBuilder,
                              iconBuilder: widget.iconBuilder,
                              distanceFormatter: widget.distanceFormatter,
                              distanceToCurrentStep: widget.distanceToCurrentStep,
                            ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...<Widget>[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _ControlBar(
                        theme: theme,
                        isExpanded: _isExpanded,
                        onToggle: _toggleExpand,
                        onClose: widget.onCloseNavigation ?? () async { await widget.onFinish(); },
                        hasArrived: widget.hasArrived,
                        distance: widget.remainingDistanceLabel,
                        duration: widget.remainingDurationLabel,
                        eta: widget.etaLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: widget.hasArrived
                        ? _ArrivalMessage(theme: theme)
                        : hasSteps
                            ? ListView.builder(
                                controller: scrollController,
                                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: widget.steps.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final ors_model.RutaStep step = widget.steps[index];
                                  final bool isActive = index == safeIndex;
                                  return _StepTile(
                                    theme: theme,
                                    icon: widget.iconBuilder(step),
                                    description: widget.descriptionBuilder(step),
                                    distanceLabel: step.distanceM > 0
                                        ? widget.distanceFormatter(step.distanceM.toDouble())
                                        : 'Distancia no disponible',
                                    durationLabel: _formatDuration(step.durationS),
                                    isActive: isActive,
                                    onTap: () => widget.onStepTap(index),
                                  );
                                },
                              )
                            : _EmptyStepsHint(theme: theme),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '';
    }
    final Duration duration = Duration(seconds: seconds);
    final int minutes = duration.inMinutes;
    final int remainingSeconds = duration.inSeconds.remainder(60);
    if (minutes == 0) {
      return '${remainingSeconds}s';
    }
    if (remainingSeconds == 0) {
      return '${minutes} min';
    }
    return '${minutes} min ${remainingSeconds}s';
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.theme,
    required this.isExpanded,
    required this.onToggle,
    required this.onClose,
    required this.hasArrived,
    this.distance,
    this.duration,
    this.eta,
  });
  final ThemeData theme;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final bool hasArrived;
  final String? distance;
  final String? duration;
  final String? eta;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = theme.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Material(
            color: cs.errorContainer,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.close, color: cs.onErrorContainer, size: 22),
              ),
            ),
          ),
          
          Expanded(
            child: Center( 
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (duration != null) 
                      _Metric(label: duration!, icon: Icons.timer_outlined),
                    if (distance != null && duration != null) 
                      const SizedBox(width: 16), 
                    if (distance != null) 
                      _Metric(label: distance!, icon: Icons.social_distance),
                    if (eta != null && (duration != null || distance != null)) 
                      const SizedBox(width: 16), 
                    if (eta != null) 
                      _Metric(label: '$eta', icon: Icons.schedule),
                  ],
                ),
              ),
            ),
          ),
          
          Material(
            color: cs.primaryContainer,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  isExpanded ? Icons.expand_more : Icons.expand_less,
                  color: cs.onPrimaryContainer,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CurrentStepCard extends StatelessWidget {
  const _CurrentStepCard({
    required this.theme,
    required this.step,
    required this.descriptionBuilder,
    required this.iconBuilder,
    required this.distanceFormatter,
    required this.distanceToCurrentStep,
  });

  final ThemeData theme;
  final ors_model.RutaStep? step;
  final String Function(ors_model.RutaStep) descriptionBuilder;
  final IconData Function(ors_model.RutaStep) iconBuilder;
  final String Function(double meters) distanceFormatter;
  final double distanceToCurrentStep;

  @override
  Widget build(BuildContext context) {
    if (step == null) {
      return _CardContainer(
        theme: theme,
        child: Text(
          'Sin instrucciones detalladas para esta ruta.',
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    final String distanceLabel = distanceToCurrentStep.isFinite && distanceToCurrentStep > 1
        ? distanceFormatter(distanceToCurrentStep)
        : step!.distanceM > 0
            ? distanceFormatter(step!.distanceM.toDouble())
            : '—';
    final String durationLabel = _formatDuration(step!.durationS);

    return _CardContainer(
      theme: theme,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(iconBuilder(step!), color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  descriptionBuilder(step!),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: <Widget>[
                    if (distanceLabel != '—')
                      _InfoChip(
                        theme: theme,
                        icon: Icons.social_distance,
                        label: distanceLabel,
                      ),
                    if (durationLabel.isNotEmpty)
                      _InfoChip(
                        theme: theme,
                        icon: Icons.timer_outlined,
                        label: durationLabel,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '';
    }
    final Duration duration = Duration(seconds: seconds);
    final int minutes = duration.inMinutes;
    final int remainingSeconds = duration.inSeconds.remainder(60);
    if (minutes == 0) {
      return '${remainingSeconds}s';
    }
    if (remainingSeconds == 0) {
      return '${minutes} min';
    }
    return '${minutes} min ${remainingSeconds}s';
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.theme,
    required this.icon,
    required this.description,
    required this.distanceLabel,
    required this.durationLabel,
    required this.isActive,
    required this.onTap,
  });

  final ThemeData theme;
  final IconData icon;
  final String description;
  final String distanceLabel;
  final String durationLabel;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withOpacity(0.12)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
            width: isActive ? 1.6 : 1,
          ),
          boxShadow: <BoxShadow>[
            if (isActive)
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isActive
                        ? colorScheme.primary
                        : colorScheme.surfaceVariant,
                    child: Icon(
                      icon,
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive ? colorScheme.primary : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            Text(
                              distanceLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (durationLabel.isNotEmpty) ...<Widget>[
                              const SizedBox(width: 12),
                              Text(
                                '•',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                durationLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.theme,
    required this.icon,
    required this.label,
  });

  final ThemeData theme;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
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

class _CardContainer extends StatelessWidget {
  const _CardContainer({
    required this.theme,
    required this.child,
  });

  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}


class _ArrivalCard extends StatelessWidget {
  const _ArrivalCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      theme: theme,
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.flag, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: 16),
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
                  'Cuando estés listo, finaliza la navegación para seguir explorando.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrivalMessage extends StatelessWidget {
  const _ArrivalMessage({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          '¡Buen trabajo! Puedes finalizar la navegación cuando quieras.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyStepsHint extends StatelessWidget {
  const _EmptyStepsHint({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Sin instrucciones detalladas para esta ruta. Continúa hacia tu destino.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
