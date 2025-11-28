import 'package:flutter/material.dart';

import '../../../core/enums/ors_profile.dart';

class TransportSelector extends StatelessWidget {
  const TransportSelector({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileSelected,
  });

  final List<OrsProfile> profiles;
  final OrsProfile selectedProfile;
  final ValueChanged<OrsProfile> onProfileSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<OrsProfile> order = <OrsProfile>[
      OrsProfile.footWalking,
      OrsProfile.cyclingRegular,
      OrsProfile.drivingCar,
    ];

    final List<OrsProfile> visibleProfiles = order
        .where((OrsProfile profile) => profiles.contains(profile))
        .toList(growable: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: visibleProfiles.map((OrsProfile profile) {
        final bool isSelected = profile == selectedProfile;
        return IconButton(
          icon: Icon(
            _iconForProfile(profile),
            color: isSelected ? theme.colorScheme.primary : Colors.grey,
          ),
          tooltip: _tooltipForProfile(profile),
          onPressed: () => onProfileSelected(profile),
        );
      }).toList(),
    );
  }

  IconData _iconForProfile(OrsProfile profile) {
    switch (profile) {
      case OrsProfile.footWalking:
        return Icons.directions_walk;
      case OrsProfile.cyclingRegular:
        return Icons.motorcycle;
      case OrsProfile.drivingCar:
        return Icons.directions_car;
    }
  }

  String _tooltipForProfile(OrsProfile profile) {
    switch (profile) {
      case OrsProfile.footWalking:
        return 'Caminando';
      case OrsProfile.cyclingRegular:
        return 'Motocicleta';
      case OrsProfile.drivingCar:
        return 'Automóvil';
    }
  }
}