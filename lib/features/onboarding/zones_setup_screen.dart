import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/flow_page.dart';
import '../../core/widgets/step_bar.dart';
import '../../core/widgets/tile_grid.dart';
import '../home/home_models.dart';
import '../home/zone_name_sheet.dart';
import '../shell/app_root.dart';

/// 06 · Pick the home's zones (step 3 of 3), then enter the home.
class ZonesSetupScreen extends StatefulWidget {
  const ZonesSetupScreen({
    required this.homeName,
    this.addingAnother = false,
    super.key,
  });

  final String homeName;
  final bool addingAnother;

  @override
  State<ZonesSetupScreen> createState() => _ZonesSetupScreenState();
}

class _ZonesSetupScreenState extends State<ZonesSetupScreen> {
  final _presets = <String>{...zonePresetKeys.take(4)};
  final _custom = <String>[];
  final _customSelected = <String>{};

  int get _count => _presets.length + _customSelected.length;

  void _togglePreset(String key) => setState(
    () => _presets.contains(key) ? _presets.remove(key) : _presets.add(key),
  );

  void _toggleCustom(String name) => setState(
    () => _customSelected.contains(name)
        ? _customSelected.remove(name)
        : _customSelected.add(name),
  );

  Future<void> _addCustom() async {
    final name = await showZoneNameSheet(context);
    if (name == null || _custom.contains(name)) return;
    setState(() {
      _custom.add(name);
      _customSelected.add(name);
    });
  }

  void _finish() {
    if (_count == 0) return;
    final app = context.app;
    app.homes.createHome(
      name: widget.homeName,
      presetKeys: [
        for (final key in zonePresetKeys)
          if (_presets.contains(key)) key,
      ],
      customZones: [
        for (final name in _custom)
          if (_customSelected.contains(name)) name,
      ],
      owner: app.account.asMember,
    );
    if (widget.addingAnother) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      enterHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FlowPage(
      top: widget.addingAnother
          ? const Align(
              alignment: Alignment.centerLeft,
              child: CalmBackButton(),
            )
          : const Align(
              alignment: Alignment.centerLeft,
              child: StepBar(current: 3, showLabel: true),
            ),
      footer: PrimaryButton(
        label: l10n.enterHomeWithZones(_count),
        onPressed: _count == 0 ? null : _finish,
      ),
      children: [
        const SizedBox(height: 20),
        FlowHeader(
          title: l10n.zonesTitle(widget.homeName),
          subtitle: Text(l10n.zonesSubtitle),
        ),
        const SizedBox(height: 24),
        TileGrid(
          children: [
            for (final key in zonePresetKeys)
              SelectTile(
                label: l10n.room(key),
                selected: _presets.contains(key),
                onTap: () => _togglePreset(key),
              ),
            for (final name in _custom)
              SelectTile(
                label: name,
                selected: _customSelected.contains(name),
                onTap: () => _toggleCustom(name),
              ),
            DashedButton(
              label: l10n.nameYourOwn,
              height: 64,
              onPressed: _addCustom,
            ),
          ],
        ),
      ],
    );
  }
}
