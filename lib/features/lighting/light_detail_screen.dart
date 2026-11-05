import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ambient_widgets.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_segment.dart';
import '../../core/widgets/flow_page.dart';
import 'light_controls.dart';
import 'light_labels.dart';
import 'light_presets.dart';
import 'lighting_service.dart';
import 'power_toggle.dart';
import 'remove_light_section.dart';

/// 11 · One light. Controls appear only for capabilities the light reports.
class LightDetailScreen extends StatefulWidget {
  const LightDetailScreen({required this.deviceId, super.key});
  final String deviceId;

  @override
  State<LightDetailScreen> createState() => _LightDetailScreenState();
}

class _LightDetailScreenState extends State<LightDetailScreen>
    with PowerToggle {
  bool _pending = false;
  bool _error = false;
  double? _brightnessDraft;
  double? _temperatureDraft;

  Future<void> _update(LightCommand command) async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _error = false;
    });
    try {
      await context.app.lighting.sendCommand(widget.deviceId, command);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
          _brightnessDraft = null;
          _temperatureDraft = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.lighting, app.homes]),
      builder: (context, _) {
        final light = app.lighting.devices
            .where((device) => device.id == widget.deviceId)
            .firstOrNull;
        if (light == null) return const _RemovedLight();
        return _buildLight(context, light);
      },
    );
  }

  Widget _buildLight(BuildContext context, LightDevice light) {
    final app = context.app;
    final l10n = context.l10n;
    final palette = context.palette;
    final caps = light.capabilities;
    final busy =
        _pending ||
        powerPending ||
        app.lighting.isCommandPending(light.id) ||
        app.lighting.isRemovalPending(light.id);
    final on = shownOn(light);
    final adjustable = light.online && on && !busy;
    final presetsEnabled = light.online && !busy;
    final zone = context.lightZone(light);
    final status = light.online ? l10n.online : l10n.offline;
    return FlowPage(
      top: FlowTopBar(
        leading: const CalmBackButton(),
        center: Column(
          children: [
            Text(
              context.lightName(light),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              zone == null ? status : '$zone · $status',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LightPresetBar(
            capabilities: caps,
            enabled: presetsEnabled,
            onSelected: _update,
          ),
          if (!app.lighting.isDemo)
            RemoveLightSection(
              service: app.lighting,
              device: light,
              controlsBusy: _pending || powerPending,
              onRemoved: () {
                if (mounted) Navigator.of(context).pop();
              },
            ),
          DemoNote(
            text: app.lighting.isDemo
                ? l10n.localControlNote
                : l10n.realControlNote,
          ),
        ],
      ),
      children: [
        const SizedBox(height: 20),
        Center(
          child: caps.brightness
              ? BrightnessPill(
                  value: _brightnessDraft ?? light.brightness,
                  enabled: adjustable,
                  onChanged: (value) =>
                      setState(() => _brightnessDraft = value),
                  onChangeEnd: (value) =>
                      _update(LightCommand(brightness: value)),
                )
              : LightStateOrb(
                  lit: light.online && caps.power && on,
                  label: !light.online
                      ? l10n.offline
                      : !caps.power
                      ? l10n.connected
                      : on
                      ? l10n.on
                      : l10n.off,
                ),
        ),
        if (caps.power) ...[
          const SizedBox(height: 22),
          Center(
            child: PowerButton(
              on: light.online && on,
              tooltip: on ? l10n.turnOff : l10n.turnOn,
              onPressed: canTogglePower(app.lighting, light) && !_pending
                  ? () => togglePower(light)
                  : null,
            ),
          ),
        ],
        if (!light.online)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              l10n.offlineDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (_error)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.updateLightError,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.danger),
              ),
            ),
          ),
        if (caps.hasTemperatureRange && caps.color) ...[
          const SizedBox(height: 26),
          CalmSegment<bool>(
            options: [(true, l10n.white), (false, l10n.color)],
            selected: light.color == null,
            onChanged: adjustable
                ? (white) => _update(
                    LightCommand(
                      whiteMode: white,
                      color: white ? null : ColorSwatches.swatches.first.$1,
                    ),
                  )
                : null,
          ),
        ],
        if (light.color == null && caps.hasTemperatureRange) ...[
          const SizedBox(height: 18),
          _temperature(light, adjustable),
        ] else if (caps.color) ...[
          const SizedBox(height: 18),
          Text(l10n.chooseFeeling, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          ColorSwatches(
            selected: light.color,
            enabled: adjustable,
            onSelected: (color) => _update(LightCommand(color: color)),
          ),
        ],
      ],
    );
  }

  Widget _temperature(LightDevice light, bool enabled) {
    final l10n = context.l10n;
    final caps = light.capabilities;
    final kelvin = (_temperatureDraft ?? light.temperature.toDouble()).clamp(
      caps.minTemperature!.toDouble(),
      caps.maxTemperature!.toDouble(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.temperature,
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.textMuted,
                ),
              ),
            ),
            Text(
              '${l10n.temperatureFeel(kelvin.round())} ${kelvin.round()}K',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ToneSlider(
          value: kelvin,
          min: caps.minTemperature!.toDouble(),
          max: caps.maxTemperature!.toDouble(),
          enabled: enabled,
          onChanged: (value) => setState(() => _temperatureDraft = value),
          onChangeEnd: (value) =>
              _update(LightCommand(temperature: value.round())),
        ),
      ],
    );
  }
}

class _RemovedLight extends StatelessWidget {
  const _RemovedLight();

  @override
  Widget build(BuildContext context) => FlowPage(
    top: FlowTopBar(
      leading: const CalmBackButton(),
      center: Text(context.l10n.unavailable),
    ),
    children: [
      const SizedBox(height: 40),
      Text(context.l10n.lightRemoved, textAlign: TextAlign.center),
    ],
  );
}
