enum OrsProfile {
  footWalking,
  drivingCar,
  cyclingRegular,
}

const List<OrsProfile> kDefaultOrsProfiles = <OrsProfile>[
  OrsProfile.footWalking,
  OrsProfile.drivingCar,
  OrsProfile.cyclingRegular,
];

extension OrsProfileX on OrsProfile {
  String get apiValue {
    switch (this) {
      case OrsProfile.footWalking:
        return 'foot-walking';
      case OrsProfile.drivingCar:
        return 'driving-car';
      case OrsProfile.cyclingRegular:
        return 'cycling-regular';
    }
  }

  String get label {
    switch (this) {
      case OrsProfile.footWalking:
        return 'A pie';
      case OrsProfile.drivingCar:
        return 'Automóvil';
      case OrsProfile.cyclingRegular:
        return 'Bicicleta';
    }
  }

  static OrsProfile? fromApiValue(String? value) {
    switch (value) {
      case 'foot-walking':
        return OrsProfile.footWalking;
      case 'driving-car':
        return OrsProfile.drivingCar;
      case 'cycling-regular':
        return OrsProfile.cyclingRegular;
      default:
        return null;
    }
  }
}

List<String> mapAllowedProfileLabels(Iterable<dynamic> allowed) {
  final List<String> labels = <String>[];
  for (final dynamic item in allowed) {
    if (item is! String) {
      continue;
    }
    final OrsProfile? profile = OrsProfileX.fromApiValue(item);
    labels.add(profile?.label ?? item);
  }
  return labels;
}
