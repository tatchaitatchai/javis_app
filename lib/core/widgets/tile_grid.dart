import 'package:flutter/widgets.dart';

/// Equal-size tiles in two columns (three or four on wide screens); one
/// column at very large text sizes so labels never clip.
class TileGrid extends StatelessWidget {
  const TileGrid({
    required this.children,
    this.spacing = 10,
    this.minTileWidth = 150,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 26;
      final fit = (constraints.maxWidth + spacing) ~/ (minTileWidth + spacing);
      final columns = largeText ? 1 : fit.clamp(2, 4);
      return Column(
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) SizedBox(height: spacing),
            // Tiles in a row share the tallest tile's height.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) SizedBox(width: spacing),
                    Expanded(
                      child: start + column < children.length
                          ? children[start + column]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
