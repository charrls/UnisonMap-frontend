import 'package:flutter/material.dart';
import '../../home/home_controller.dart';

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onCancelSearch,
  });

  final HomeController controller;
  final bool isSearching;
  final VoidCallback onCancelSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(isSearching ? 20 : 16);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: isSearching
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.white,
        elevation: isSearching ? 4 : 0,
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSearching ? 12 : 0,
            vertical: isSearching ? 4 : 0,
          ),
          child: Row(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                child: isSearching
                    ? const SizedBox.shrink()
                    : _CompactActionButton(
                        heroTag: 'notificaciones',
                        icon: Icons.notifications,
                        colorScheme: colorScheme,
                        onPressed: () {},
                      ),
              ),
              if (!isSearching) const SizedBox(width: 8),
              Expanded(
                child: TextField(
                    controller: controller.searchController,
                    focusNode: controller.searchFocusNode,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar ubicación...',
                    filled: true,
                      fillColor: Colors.white,
                    prefixIcon: isSearching
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: onCancelSearch,
                          )
                        : const Icon(Icons.search),
                    suffixIcon: isSearching && controller.searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              controller.searchController.clear();
                              controller.actualizarSugerencias('');
                              controller.updateSearchPanelVisibility();
                            },
                            tooltip: 'Limpiar búsqueda',
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    controller.actualizarSugerencias(value);
                    controller.updateSearchPanelVisibility();
                  },
                  onTap: () {
                    controller.startSearch();
                    controller.updateSearchPanelVisibility();
                  },
                  onSubmitted: (value) {
                    controller.buscarUbicacion(value);
                  },
                ),
              ),
              if (!isSearching) const SizedBox(width: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                clipBehavior: Clip.none,
                alignment: Alignment.centerRight,
                child: isSearching
                    ? const SizedBox.shrink()
                    : _CompactActionButton(
                        heroTag: 'config',
                        icon: Icons.settings,
                        iconColor: Colors.blueGrey,
                        colorScheme: colorScheme,
                        onPressed: () {},
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.heroTag,
    required this.icon,
    required this.colorScheme,
    this.iconColor,
    this.onPressed,
  });

  final String heroTag;
  final IconData icon;
  final ColorScheme colorScheme;
  final Color? iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: FloatingActionButton(
        heroTag: heroTag,
        mini: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        onPressed: onPressed,
        child: Icon(
          icon,
          color: iconColor ?? colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}