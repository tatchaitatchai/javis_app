import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/flow_page.dart';
import '../shell/app_root.dart';

/// Launch with a saved session while the server can't be reached. Going to the
/// welcome screen here would look like being signed out.
class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FlowPage(
      footer: PrimaryButton(
        label: l10n.tryAgain,
        onPressed: () => restoreSession(context.app),
      ),
      children: [
        const SizedBox(height: 64),
        FlowHeader(
          title: l10n.cantConnectTitle,
          subtitle: Text(l10n.cantConnectBody),
        ),
      ],
    );
  }
}
