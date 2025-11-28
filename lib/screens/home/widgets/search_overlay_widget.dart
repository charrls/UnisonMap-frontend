import 'dart:ui';

import 'package:flutter/material.dart';

import '../../home/home_controller.dart';
import 'suggestion_panel.dart';

class SearchOverlayWidget extends StatelessWidget {
  const SearchOverlayWidget({
    super.key,
    required this.isVisible,
    required this.controller,
    required this.onClose,
    required this.onSuggestionTap,
    required this.topPadding,
  });

  final bool isVisible;
  final HomeController controller;
  final VoidCallback onClose;
  final ValueChanged<dynamic> onSuggestionTap;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isVisible,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: isVisible
              ? _OverlayContent(
                  key: const ValueKey('searchOverlayVisible'),
                  controller: controller,
                  onClose: onClose,
                  onSuggestionTap: onSuggestionTap,
                  topPadding: topPadding,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _OverlayContent extends StatelessWidget {
  const _OverlayContent({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onSuggestionTap,
    required this.topPadding,
  });

  final HomeController controller;
  final VoidCallback onClose;
  final ValueChanged<dynamic> onSuggestionTap;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: colorScheme.surface.withValues(alpha: 0.55),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  offset: const Offset(0, -0.02),
                  child: _SearchResultsCard(
                    controller: controller,
                    onClose: onClose,
                    onSuggestionTap: onSuggestionTap,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResultsCard extends StatelessWidget {
  const _SearchResultsCard({
    required this.controller,
    required this.onClose,
    required this.onSuggestionTap,
  });

  final HomeController controller;
  final VoidCallback onClose;
  final ValueChanged<dynamic> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
          final screenHeight = MediaQuery.sizeOf(context).height;
          final rawMaxHeight = (constraints.maxHeight.isFinite ? constraints.maxHeight : screenHeight) - viewInsetsBottom;
          final availableHeight = rawMaxHeight.isFinite && rawMaxHeight > 0 ? rawMaxHeight : screenHeight * 0.6;
          const double minInteractiveHeight = 360;

          final header = SizedBox.shrink();
          final divider = Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          );
          final footer = Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClose,
                child: const Text('Cerrar'),
              ),
            ),
          );

          if (availableHeight < minInteractiveHeight) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: viewInsetsBottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  divider,
                  _SuggestionPanelContainer(
                    controller: controller,
                    colorScheme: colorScheme,
                    onSuggestionTap: onSuggestionTap,
                    scrollPhysics: const NeverScrollableScrollPhysics(),
                  ),
                  footer,
                ],
              ),
            );
          }

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: availableHeight),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                divider,
                Expanded(
                  child: _SuggestionPanelContainer(
                    controller: controller,
                    colorScheme: colorScheme,
                    onSuggestionTap: onSuggestionTap,
                  ),
                ),
                footer,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuggestionPanelContainer extends StatelessWidget {
  const _SuggestionPanelContainer({
    required this.controller,
    required this.colorScheme,
    required this.onSuggestionTap,
    this.scrollPhysics,
  });

  final HomeController controller;
  final ColorScheme colorScheme;
  final ValueChanged<dynamic> onSuggestionTap;
  final ScrollPhysics? scrollPhysics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SuggestionPanel(
        searchController: controller.searchController,
        historialBusquedas: controller.historialBusquedas,
        sugerencias: controller.sugerencias,
        onSuggestionTap: onSuggestionTap,
        borderRadius: BorderRadius.circular(16),
        backgroundColor: Colors.white,
        scrollPhysics: scrollPhysics,
      ),
    );
  }
}
