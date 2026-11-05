import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_sheet.dart';
import '../../core/widgets/calm_text_field.dart';

/// Asks for one short name (a zone or a home). Returns null when dismissed.
Future<String?> showZoneNameSheet(
  BuildContext context, {
  String? title,
  String? label,
  String initial = '',
}) {
  final l10n = context.l10n;
  final sheetTitle = title ?? l10n.newZoneTitle;
  final fieldLabel = label ?? l10n.zoneName;
  return showCalmSheet<String>(
    context: context,
    builder: (_) =>
        _NameForm(title: sheetTitle, label: fieldLabel, initial: initial),
  );
}

class _NameForm extends StatefulWidget {
  const _NameForm({
    required this.title,
    required this.label,
    required this.initial,
  });

  final String title;
  final String label;
  final String initial;

  @override
  State<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<_NameForm> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        CalmTextField(
          label: widget.label,
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: context.l10n.save,
          onPressed: _name.text.trim().isEmpty ? null : _save,
        ),
      ],
    ),
  );
}
