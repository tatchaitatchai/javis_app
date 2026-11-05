import 'package:flutter/widgets.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import 'lighting_service.dart';

/// How a light is named and described everywhere in the UI.
extension LightLabels on BuildContext {
  /// A name typed after pairing wins; demo names are translated; provider
  /// names are shown exactly as the user set them.
  String lightName(LightDevice device) {
    final custom = app.homes.customDeviceName(device.id);
    if (custom != null) return custom;
    return app.lighting.isDemo
        ? l10n.demoDevice(device.id, device.name)
        : device.name;
  }

  String? lightZone(LightDevice device) {
    final zone = app.homes.zoneFor(device);
    if (zone != null) return zone.label(l10n);
    if (device.room.isEmpty) return null;
    return app.lighting.isDemo ? l10n.room(device.room) : device.room;
  }

  /// Short state: “80%”, “On”, “Off”, “Offline” or “State unavailable”.
  String lightState(LightDevice device) {
    if (!device.online) return l10n.offline;
    if (!device.capabilities.power) return l10n.stateUnavailable;
    if (!device.isOn) return l10n.off;
    return device.capabilities.brightness
        ? '${(device.brightness * 100).round()}%'
        : l10n.on;
  }

  String lightSubtitle(LightDevice device, {bool includeZone = true}) {
    final zone = includeZone ? lightZone(device) : null;
    final state = device.online ? lightState(device) : l10n.notResponding;
    return zone == null ? state : '$zone · $state';
  }
}
