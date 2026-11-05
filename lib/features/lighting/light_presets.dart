import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pressable.dart';
import 'lighting_service.dart';

/// Quick looks from design 11. Only presets the light can perform are shown.
class LightPresetBar extends StatelessWidget {
  const LightPresetBar({
    required this.capabilities,
    required this.enabled,
    required this.onSelected,
    super.key,
  });

  final LightCapabilities capabilities;
  final bool enabled;
  final ValueChanged<LightCommand> onSelected;

  List<(String, Color, LightCommand)> _presets() {
    int clampK(int kelvin) => capabilities.hasTemperatureRange
        ? kelvin.clamp(
            capabilities.minTemperature!,
            capabilities.maxTemperature!,
          )
        : kelvin;
    return [
      (
        'Reading',
        const Color(0xFFF2C57C),
        LightCommand(
          isOn: true,
          brightness: .9,
          temperature: clampK(4000),
          whiteMode: true,
        ),
      ),
      (
        'Relax',
        const Color(0xFFF7D9A8),
        LightCommand(
          isOn: true,
          brightness: .45,
          temperature: clampK(2700),
          whiteMode: true,
        ),
      ),
      (
        'Bright',
        const Color(0xFFE6EEF7),
        LightCommand(
          isOn: true,
          brightness: 1,
          temperature: clampK(5500),
          whiteMode: true,
        ),
      ),
      (
        'Night',
        const Color(0xFFB9A3D6),
        const LightCommand(
          isOn: true,
          brightness: .1,
          color: Color(0xFFB9A3D6),
        ),
      ),
    ].where((preset) => preset.$3.supports(capabilities)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final presets = _presets();
    if (presets.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    return Row(
      children: [
        for (var i = 0; i < presets.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Pressable(
              onPressed: enabled ? () => onSelected(presets[i].$3) : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: palette.paper,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: presets[i].$2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.lightPreset(presets[i].$1),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
