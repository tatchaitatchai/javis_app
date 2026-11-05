import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

/// Phone-sized reading width on portrait tablets; two columns when space permits.
class AdaptivePage extends StatelessWidget {
  const AdaptivePage({
    required this.children,
    this.expanded = false,
    super.key,
  });
  final List<Widget> children;
  final bool expanded;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          expanded &&
          constraints.maxWidth >= 1000 &&
          MediaQuery.textScalerOf(context).scale(16) <= 22;
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 1168 : 704),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              wide ? 32 : 24,
              20,
              wide ? 32 : 24,
              24,
            ),
            children: children,
          ),
        ),
      );
    },
  );
}

class CalmColumns extends StatelessWidget {
  const CalmColumns({required this.leading, required this.trailing, super.key});
  final Widget leading;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 900
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leading),
              const SizedBox(width: 32),
              Expanded(child: trailing),
            ],
          )
        : Column(children: [leading, trailing]),
  );
}

class DemoNote extends StatelessWidget {
  const DemoNote({this.text, super.key});
  final String? text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Text(
      text ?? context.l10n.prototypeNote,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        height: 1.5,
        color: CalmColors.muted(context),
      ),
    ),
  );
}
