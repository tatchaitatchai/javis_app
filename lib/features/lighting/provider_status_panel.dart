import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/widgets/calm_surfaces.dart';
import 'lighting_service.dart';

/// Real-device mode only: explains provider readiness without inventing
/// demo lights (spec 004).
class ProviderStatusPanel extends StatelessWidget {
  const ProviderStatusPanel({required this.service, super.key});
  final LightingService service;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (service.readiness == LightingReadiness.ready &&
        service.devices.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Semantics(
        liveRegion: true,
        child: CalmPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.providerStatus(service.readiness.name),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.providerDescription(service.readiness.name),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (service.devices.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.noConnectedLights,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
