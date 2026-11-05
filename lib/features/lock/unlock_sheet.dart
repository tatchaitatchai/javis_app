import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_sheet.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/slide_to_confirm.dart';

/// 13 · Confirm before unlocking. The status changes only when the lock
/// reports back, never on send.
Future<void> showUnlockSheet(BuildContext context) => showCalmSheet<void>(
  context: context,
  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
  builder: (sheetContext) {
    final l10n = sheetContext.l10n;
    final app = sheetContext.app;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.unlockQuestion(l10n.frontDoor),
          textAlign: TextAlign.center,
          style: Theme.of(sheetContext).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.unlockRelocks,
          textAlign: TextAlign.center,
          style: Theme.of(sheetContext).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        SlideToConfirm(
          label: l10n.slideToUnlock,
          icon: CupertinoIcons.lock_open_fill,
          onConfirmed: () {
            app.lock.unlock(actor: app.account.name);
            Navigator.of(sheetContext).pop();
          },
        ),
        const SizedBox(height: 14),
        Text(
          l10n.faceIdNotInPreview,
          textAlign: TextAlign.center,
          style: Theme.of(sheetContext).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        InfoNote(
          icon: CupertinoIcons.info_circle,
          tone: NoteTone.warm,
          text: l10n.unlockReportedOnly,
        ),
        const SizedBox(height: 8),
        QuietButton(
          label: l10n.cancel,
          accent: false,
          onPressed: () => Navigator.of(sheetContext).pop(),
        ),
      ],
    );
  },
);
