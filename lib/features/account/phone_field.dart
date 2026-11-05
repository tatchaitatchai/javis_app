import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/calm_text_field.dart';
import 'account_store.dart';

/// Thai mobile number field with the fixed +66 box (sign-in and invites).
class ThaiPhoneField extends StatelessWidget {
  const ThaiPhoneField({
    required this.label,
    required this.controller,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => CalmTextField(
    label: label,
    controller: controller,
    hint: '08X XXX XXXX',
    autofocus: autofocus,
    keyboardType: TextInputType.phone,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.telephoneNumberNational],
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
      const ThaiMobileFormatter(),
    ],
    fontSize: 19,
    letterSpacing: .6,
    prefix: const CountryCodeBox(),
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}

/// Groups digits as `081 234 5678` while typing.
class ThaiMobileFormatter extends TextInputFormatter {
  const ThaiMobileFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = formatThaiMobile(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
