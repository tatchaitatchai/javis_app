import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import 'lighting_service.dart';

/// Optimistic on/off shared by tiles, rows and the detail page.
///
/// The switch flips in the same frame as the tap; the confirmed provider state
/// takes over when the command finishes, and a failure flips it back.
mixin PowerToggle<T extends StatefulWidget> on State<T> {
  bool? _optimisticOn;
  bool _powerPending = false;

  bool get powerPending => _powerPending;

  bool shownOn(LightDevice device) => _optimisticOn ?? device.isOn;

  bool canTogglePower(LightingService service, LightDevice device) =>
      device.online &&
      device.capabilities.power &&
      !_powerPending &&
      !service.isCommandPending(device.id) &&
      !service.isRemovalPending(device.id);

  Future<void> togglePower(LightDevice device) async {
    final service = context.app.lighting;
    if (!canTogglePower(service, device)) return;
    final target = !device.isOn;
    setState(() {
      _optimisticOn = target;
      _powerPending = true;
    });
    try {
      await service.sendCommand(device.id, LightCommand(isOn: target));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.changeLightError)),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _optimisticOn = null;
          _powerPending = false;
        });
      }
    }
  }
}
