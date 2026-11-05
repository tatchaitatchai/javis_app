import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ambient_widgets.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/tile_grid.dart';
import '../lighting/light_cards.dart';
import '../lighting/provider_status_panel.dart';
import '../lock/lock_card.dart';
import '../lock/lock_store.dart';
import '../pairing/device_type_screen.dart';
import '../scenes/scene_strip.dart';
import '../voice/voice_screen.dart';
import 'home_models.dart';
import 'home_switcher_sheet.dart';
import 'zone_screen.dart';

/// 09 · Home dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.onOpenScenes, super.key});
  final VoidCallback onOpenScenes;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _zoneFilter;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.homes, app.lighting]),
      builder: (context, _) {
        final home = app.homes.activeHome;
        if (home == null) return const SizedBox.shrink();
        final zone = home.zones
            .where((zone) => zone.id == _zoneFilter)
            .firstOrNull;
        return SafeArea(
          bottom: false,
          child: AdaptivePage(
            children: [
              _Header(home: home),
              if (home.connected) ...[
                const _Summary(),
                if (!app.lighting.isDemo)
                  ProviderStatusPanel(service: app.lighting),
                const SizedBox(height: 16),
                const LockCard(),
              ],
              SectionHeader(
                context.l10n.scenesTab,
                padding: const EdgeInsets.only(top: 20, bottom: 4),
                action: QuietButton(
                  label: context.l10n.all,
                  onPressed: widget.onOpenScenes,
                ),
              ),
              const _SceneRow(),
              const SizedBox(height: 12),
              _ZoneChips(
                home: home,
                selected: zone?.id,
                onSelected: (id) => setState(() => _zoneFilter = id),
              ),
              if (zone != null) _ZoneLink(zone: zone),
              const SizedBox(height: 12),
              if (home.connected)
                _DeviceGrid(zone: zone)
              else
                _PreviewHomeNote(home: home),
              if (home.connected && app.lighting.isDemo)
                DemoNote(text: context.l10n.demoLightsNote),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.home});
  final Home home;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Pressable(
              onPressed: () => showHomeSwitcher(context),
              semanticLabel: l10n.switchHomeLabel(home.name),
              excludeChildSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        home.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(CupertinoIcons.chevron_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        CircleIconButton(
          icon: CupertinoIcons.mic,
          tooltip: l10n.voiceControl,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => const VoiceScreen(),
            ),
          ),
        ),
        if (home.connected && home.canManage)
          CircleIconButton(
            icon: CupertinoIcons.add,
            tooltip: l10n.addDevice,
            filled: true,
            onPressed: () => openAddDevice(context),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l10n = context.l10n;
    return ListenableBuilder(
      // Listens itself: as a const child it is not rebuilt by its parent.
      listenable: Listenable.merge([app.lighting, app.lock]),
      builder: (context, _) {
        final lights = app.lighting.devices;
        final unknown = lights.any((light) => !light.capabilities.power);
        final on = lights
            .where(
              (light) => light.online && light.capabilities.power && light.isOn,
            )
            .length;
        final lightsText = app.lighting.isDemo
            ? l10n.lightsOn(on)
            : unknown
            ? l10n.realConnectedSummary(lights.where((l) => l.online).length)
            : l10n.realHomeSummary(on);
        final doorText = app.lock.status == LockStatus.locked
            ? l10n.doorLocked
            : l10n.doorUnlocked;
        return Text(
          '$lightsText · $doorText',
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }
}

class _SceneRow extends StatelessWidget {
  const _SceneRow();

  @override
  Widget build(BuildContext context) {
    final scenes = context.app.scenes;
    return ListenableBuilder(
      listenable: scenes,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (final scene in scenes.scenes.take(4)) ...[
              ScenePill(scene: scene),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZoneChips extends StatelessWidget {
  const _ZoneChips({
    required this.home,
    required this.selected,
    required this.onSelected,
  });

  final Home home;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(
      children: [
        SelectPill(
          label: context.l10n.all,
          filled: true,
          height: 36,
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final zone in home.zones) ...[
          const SizedBox(width: 8),
          SelectPill(
            label: zone.label(context.l10n),
            filled: true,
            height: 36,
            selected: selected == zone.id,
            onTap: () => onSelected(zone.id),
          ),
        ],
      ],
    ),
  );
}

class _ZoneLink extends StatelessWidget {
  const _ZoneLink({required this.zone});
  final Zone zone;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: QuietButton(
      label: context.l10n.openZone(zone.label(context.l10n)),
      icon: CupertinoIcons.arrow_up_right,
      onPressed: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(builder: (_) => ZoneScreen(zoneId: zone.id)),
      ),
    ),
  );
}

class _DeviceGrid extends StatelessWidget {
  const _DeviceGrid({required this.zone});
  final Zone? zone;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final lights = [
      for (final light in app.lighting.devices)
        if (zone == null || app.homes.zoneIdFor(light) == zone!.id) light,
    ];
    if (lights.isEmpty) return _EmptyLights(zone: zone);
    return AnimatedSize(
      duration: Motion.of(context, Motion.standard),
      curve: Motion.curve,
      alignment: Alignment.topCenter,
      child: TileGrid(
        children: [
          for (final light in lights)
            LightTile(key: ValueKey(light.id), device: light),
        ],
      ),
    );
  }
}

class _EmptyLights extends StatelessWidget {
  const _EmptyLights({required this.zone});
  final Zone? zone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final home = context.app.homes.activeHome;
    return CalmPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.lightbulb,
            size: 32,
            color: context.palette.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            zone == null ? l10n.noLightsYet : l10n.noLightsInZone,
            textAlign: TextAlign.center,
          ),
          if (home?.canManage ?? false) ...[
            const SizedBox(height: 12),
            QuietButton(
              label: l10n.addDevice,
              icon: CupertinoIcons.add,
              onPressed: () => openAddDevice(context, zoneId: zone?.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewHomeNote extends StatelessWidget {
  const _PreviewHomeNote({required this.home});
  final Home home;

  @override
  Widget build(BuildContext context) => InfoNote(
    icon: CupertinoIcons.house,
    title: context.l10n.previewHomeTitle,
    text: context.l10n.previewHomeBody(home.previewDeviceCount),
  );
}
