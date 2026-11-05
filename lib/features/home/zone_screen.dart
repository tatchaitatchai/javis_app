import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/ambient_widgets.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/flow_page.dart';
import '../lighting/light_cards.dart';
import '../lighting/lighting_service.dart';
import '../pairing/device_type_screen.dart';
import '../scenes/scene_editor_screen.dart';
import '../scenes/scene_strip.dart';
import 'home_settings_screen.dart';

/// 10 · One zone: its lights, “turn all off”, and the scenes that use it.
class ZoneScreen extends StatefulWidget {
  const ZoneScreen({required this.zoneId, super.key});
  final String zoneId;

  @override
  State<ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends State<ZoneScreen> {
  bool _turningOff = false;

  Future<void> _turnAllOff(List<LightDevice> lights) async {
    final service = context.app.lighting;
    setState(() => _turningOff = true);
    var failed = false;
    for (final light in lights) {
      if (!light.online || !light.capabilities.power || !light.isOn) continue;
      try {
        await service.sendCommand(light.id, const LightCommand(isOn: false));
      } catch (_) {
        failed = true;
      }
    }
    if (!mounted) return;
    setState(() => _turningOff = false);
    if (failed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.changeLightError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([app.homes, app.lighting, app.scenes]),
          builder: (context, _) {
            final home = app.homes.activeHome;
            final zone = home?.zones
                .where((zone) => zone.id == widget.zoneId)
                .firstOrNull;
            if (home == null || zone == null) {
              return const Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CalmBackButton(),
                ),
              );
            }
            final lights = [
              for (final light in app.homes.lightsIn(app.lighting))
                if (app.homes.zoneIdFor(light) == zone.id) light,
            ];
            final on = lights
                .where((l) => l.online && l.capabilities.power && l.isOn)
                .length;
            final scenes = zone.presetKey == null
                ? const []
                : app.scenes.scenes
                      .where((scene) => scene.touchesZone(zone.presetKey!))
                      .toList();
            return AdaptivePage(
              children: [
                FlowTopBar(
                  leading: const CalmBackButton(),
                  trailing: home.canManage
                      ? CircleIconButton(
                          icon: CupertinoIcons.pencil,
                          tooltip: l10n.editZones,
                          plain: true,
                          onPressed: () => Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => const HomeSettingsScreen(),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FlowHeader(
                        title: zone.label(l10n),
                        subtitle: Text(
                          lights.isEmpty
                              ? l10n.noLightsInZone
                              : l10n.onOfLights(on, lights.length),
                        ),
                      ),
                    ),
                    if (on > 0) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 132,
                        child: SecondaryButton(
                          label: l10n.turnAllOff,
                          loading: _turningOff,
                          onPressed: () => _turnAllOff(lights),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                for (final light in lights) ...[
                  LightRowCard(key: ValueKey(light.id), device: light),
                  const SizedBox(height: 10),
                ],
                if (scenes.isNotEmpty) ...[
                  SectionHeader(l10n.scenesUsingZone),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final scene in scenes)
                        ScenePill(
                          scene: scene,
                          onPressed: () => Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) =>
                                  SceneEditorScreen(sceneId: scene.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (home.connected && home.canManage) ...[
                  const SizedBox(height: 28),
                  DashedButton(
                    label: l10n.addDeviceTo(zone.label(l10n)),
                    onPressed: () => openAddDevice(context, zoneId: zone.id),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
