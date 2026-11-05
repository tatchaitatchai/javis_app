import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import 'lighting_service.dart';

/// The confirmation is intentionally separate from the light controls.
class RemoveLightSection extends StatefulWidget {
  const RemoveLightSection({
    required this.service,
    required this.device,
    required this.onRemoved,
    this.controlsBusy = false,
    super.key,
  });

  final LightingService service;
  final LightDevice device;
  final VoidCallback onRemoved;
  final bool controlsBusy;

  @override
  State<RemoveLightSection> createState() => _RemoveLightSectionState();
}

class _RemoveLightSectionState extends State<RemoveLightSection> {
  bool _removing = false;
  bool _failed = false;

  Future<void> _confirmAndRemove() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.lightbulb,
                size: 32,
                color: CalmColors.muted(sheetContext),
              ),
              const SizedBox(height: 18),
              Text(
                sheetContext.l10n.removeLightTitle,
                style: Theme.of(sheetContext).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                sheetContext.l10n.removeLightDescription(widget.device.name),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: Text(sheetContext.l10n.removeLight),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: Text(sheetContext.l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _removing = true;
      _failed = false;
    });
    try {
      await widget.service.removeDevice(widget.device.id);
      widget.onRemoved();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        _removing ||
        widget.controlsBusy ||
        widget.service.isCommandPending(widget.device.id) ||
        widget.service.isRemovalPending(widget.device.id);
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : _confirmAndRemove,
              icon: _removing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.trash, size: 20),
              label: Text(context.l10n.removeLight),
            ),
          ),
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  context.l10n.removeLightError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
