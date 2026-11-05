import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/motion/entrance.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_sheet.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../lighting/lighting_service.dart';

/// Bluetooth state and the lights found so far (spec 013).
class NearbyScanView extends StatelessWidget {
  const NearbyScanView({
    required this.bluetooth,
    required this.devices,
    required this.onChoose,
    super.key,
  });

  final BluetoothState bluetooth;
  final List<NearbyDevice> devices;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blocked = switch (bluetooth) {
      BluetoothState.off => l10n.bluetoothOff,
      BluetoothState.unauthorized => l10n.bluetoothDenied,
      BluetoothState.unsupported => l10n.bluetoothUnsupported,
      BluetoothState.unknown || BluetoothState.on => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (blocked != null)
          Semantics(
            liveRegion: true,
            child: InfoNote(
              icon: CupertinoIcons.bluetooth,
              tone: NoteTone.warm,
              text: blocked,
            ),
          )
        else
          CalmPanel(
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(l10n.nearbySearching),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        if (devices.isEmpty)
          InfoNote(
            icon: CupertinoIcons.lightbulb,
            text: l10n.nearbySearchingHint,
          )
        else
          NearbyDeviceList(devices: devices, onChoose: onChoose),
      ],
    );
  }
}

class NearbyDeviceList extends StatelessWidget {
  const NearbyDeviceList({
    required this.devices,
    required this.onChoose,
    super.key,
  });

  final List<NearbyDevice> devices;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < devices.length; i++)
          Entrance(
            order: i,
            child: ListRow(
              key: ValueKey('nearby-${devices[i].id}'),
              leading: Icon(
                CupertinoIcons.lightbulb_fill,
                color: palette.accentDeep,
              ),
              title: context.l10n.nearbyLight(i + 1),
              subtitle: context.l10n.nearbyReady,
              chevron: true,
              onTap: () => onChoose(devices[i].id),
            ),
          ),
      ],
    );
  }
}

/// Slides up when the scan first finds something, like a system accessory
/// prompt. Resolves to the chosen [NearbyDevice.id], or null when dismissed.
Future<String?> showNearbyFoundSheet(
  BuildContext context,
  LightingService service,
) => showCalmSheet<String>(
  context: context,
  builder: (sheetContext) => ListenableBuilder(
    listenable: service,
    builder: (_, _) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sheetContext.l10n.nearbyFoundTitle,
          style: Theme.of(sheetContext).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          sheetContext.l10n.nearbyFoundBody,
          style: Theme.of(sheetContext).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        NearbyDeviceList(
          devices: service.nearbyDevices,
          onChoose: (id) => Navigator.of(sheetContext).pop(id),
        ),
      ],
    ),
  ),
);
