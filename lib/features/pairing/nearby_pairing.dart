import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/motion/entrance.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../lighting/lighting_service.dart';
import 'nearby_device_icon.dart';
import 'nearby_radar.dart';

/// The radar, the search status and everything found so far (spec 018).
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
        NearbyRadar(
          devices: devices,
          searching: blocked == null,
          onChoose: onChoose,
        ),
        const SizedBox(height: 14),
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
          Semantics(
            liveRegion: true,
            child: Text(
              devices.isEmpty
                  ? l10n.nearbySearching
                  : l10n.nearbyFoundCount(devices.length),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 14),
        if (devices.isNotEmpty)
          _FoundDevices(devices: devices, onChoose: onChoose)
        else if (blocked == null)
          InfoNote(
            icon: CupertinoIcons.info_circle,
            text: l10n.nearbySearchingHint,
          ),
      ],
    );
  }
}

class _FoundDevices extends StatelessWidget {
  const _FoundDevices({required this.devices, required this.onChoose});

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
            key: ValueKey('nearby-${devices[i].id}'),
            child: ListRow(
              leading: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accentTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: NearbyDeviceIcon(device: devices[i], size: 24),
              ),
              title: context.nearbyDeviceName(devices[i], i),
              subtitle: context.l10n.nearbyReady,
              trailing: const _AddLabel(),
              onTap: () => onChoose(devices[i].id),
            ),
          ),
      ],
    );
  }
}

/// Looks like a button, but the whole row is the tap target.
class _AddLabel extends StatelessWidget {
  const _AddLabel();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.strong,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.nearbyAdd,
        style: TextStyle(
          color: palette.onStrong,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
