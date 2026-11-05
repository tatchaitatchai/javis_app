import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Labelled text field on paper with the design's sage focus ring.
class CalmTextField extends StatelessWidget {
  const CalmTextField({
    required this.label,
    this.controller,
    this.fieldKey,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.fontSize = 18,
    this.letterSpacing,
    this.private = false,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final Key? fieldKey;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final double fontSize;
  final double? letterSpacing;

  /// Turns off suggestions and keyboard learning (Wi-Fi names, passwords).
  final bool private;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final field = TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      autofocus: autofocus,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: !private,
      enableIMEPersonalizedLearning: !private,
      style: TextStyle(
        fontSize: fontSize,
        color: palette.text,
        letterSpacing: letterSpacing,
      ),
      decoration: calmInputDecoration(
        context,
        hint: hint,
        suffix: suffix,
      ).copyWith(labelText: null),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (prefix == null)
          field
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              prefix!,
              const SizedBox(width: 10),
              Expanded(child: field),
            ],
          ),
      ],
    );
  }
}

InputDecoration calmInputDecoration(
  BuildContext context, {
  String? hint,
  Widget? suffix,
}) {
  final palette = context.palette;
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: palette.textFaint),
    filled: true,
    fillColor: palette.paper,
    isDense: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    suffixIcon: suffix,
    enabledBorder: border(palette.line, 1.5),
    disabledBorder: border(palette.hairline, 1.5),
    focusedBorder: border(palette.accent, 2),
    errorBorder: border(palette.danger, 1.5),
    focusedErrorBorder: border(palette.danger, 2),
  );
}

/// The non-editable “+66” box shown beside phone fields.
class CountryCodeBox extends StatelessWidget {
  const CountryCodeBox({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.line, width: 1.5),
      ),
      child: const Text('+66', style: TextStyle(fontSize: 17)),
    );
  }
}
