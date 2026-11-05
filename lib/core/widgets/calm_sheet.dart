import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Paper bottom sheet with a grab handle, sized to its content.
Future<T?> showCalmSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  EdgeInsets padding = const EdgeInsets.fromLTRB(20, 10, 20, 24),
}) {
  final palette = context.palette;
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: palette.paper,
    barrierColor: palette.scrim,
    constraints: const BoxConstraints(maxWidth: 560),
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            builder(sheetContext),
          ],
        ),
      ),
    ),
  );
}
