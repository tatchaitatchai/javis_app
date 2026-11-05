import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/calm_switch.dart';
import '../../core/widgets/pressable.dart';
import 'light_detail_screen.dart';
import 'light_labels.dart';
import 'lighting_service.dart';
import 'power_toggle.dart';

void openLight(BuildContext context, LightDevice device) =>
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => LightDetailScreen(deviceId: device.id),
      ),
    );

/// Dashboard grid tile (design 09): warm when on, quiet when off.
class LightTile extends StatefulWidget {
  const LightTile({required this.device, super.key});
  final LightDevice device;

  @override
  State<LightTile> createState() => _LightTileState();
}

class _LightTileState extends State<LightTile> with PowerToggle {
  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final palette = context.palette;
    final service = context.app.lighting;
    final on = shownOn(device) && device.online && device.capabilities.power;
    final name = context.lightName(device);
    final background = !device.online
        ? palette.raised
        : on
        ? palette.glow
        : palette.paper;
    return Stack(
      fit: StackFit.expand,
      children: [
        Pressable(
          onPressed: () => openLight(context, device),
          pressedScale: .97,
          semanticLabel: '$name, ${context.lightSubtitle(device)}',
          excludeChildSemantics: true,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.curve,
            constraints: const BoxConstraints(minHeight: 116),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BulbIcon(on: on, online: device.online),
                const SizedBox(height: 22),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.lightSubtitle(device),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: palette.textMuted),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 6,
          child: !device.online
              ? Padding(
                  padding: const EdgeInsets.only(top: 10, right: 4),
                  child: StatusBadge(context.l10n.offline),
                )
              : device.capabilities.power
              ? CalmSwitch(
                  compact: true,
                  value: shownOn(device),
                  busy: powerPending,
                  semanticLabel: context.l10n.powerOf(name),
                  onChanged: canTogglePower(service, device)
                      ? (_) => togglePower(device)
                      : null,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Zone list row (design 10) with a brightness bar.
class LightRowCard extends StatefulWidget {
  const LightRowCard({required this.device, super.key});
  final LightDevice device;

  @override
  State<LightRowCard> createState() => _LightRowCardState();
}

class _LightRowCardState extends State<LightRowCard> with PowerToggle {
  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final palette = context.palette;
    final service = context.app.lighting;
    final l10n = context.l10n;
    final on = shownOn(device) && device.online && device.capabilities.power;
    final name = context.lightName(device);
    final detail = on && device.capabilities.brightness
        ? '${context.lightState(device)} · '
              '${device.color == null ? l10n.temperatureFeel(device.temperature) : l10n.color}'
        : context.lightSubtitle(device, includeZone: false);
    return AnimatedContainer(
      duration: Motion.of(context, Motion.standard),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: !device.online
            ? palette.raised
            : on
            ? palette.glow
            : palette.paper,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onPressed: () => openLight(context, device),
              pressedScale: .98,
              semanticLabel: '$name, $detail',
              excludeChildSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Row(
                  children: [
                    _BulbIcon(on: on, online: device.online),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                detail,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                          if (on && device.capabilities.brightness) ...[
                            const SizedBox(height: 8),
                            _BrightnessBar(value: device.brightness),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (!device.online)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StatusBadge(l10n.offline),
            )
          else if (device.capabilities.power)
            CalmSwitch(
              value: shownOn(device),
              busy: powerPending,
              semanticLabel: l10n.powerOf(name),
              onChanged: canTogglePower(service, device)
                  ? (_) => togglePower(device)
                  : null,
            ),
        ],
      ),
    );
  }
}

class _BulbIcon extends StatelessWidget {
  const _BulbIcon({required this.on, required this.online});
  final bool on;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.quick),
      child: Icon(
        !online
            ? CupertinoIcons.wifi_slash
            : on
            ? CupertinoIcons.lightbulb_fill
            : CupertinoIcons.lightbulb,
        key: ValueKey((on, online)),
        size: 26,
        color: on ? palette.goldDeep : palette.textMuted,
      ),
    );
  }
}

class _BrightnessBar extends StatelessWidget {
  const _BrightnessBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: palette.glowTrack)),
            AnimatedFractionallySizedBox(
              duration: Motion.of(context, Motion.standard),
              curve: Motion.curve,
              widthFactor: value.clamp(0, 1),
              heightFactor: 1,
              child: ColoredBox(color: palette.goldDeep),
            ),
          ],
        ),
      ),
    );
  }
}
