import 'package:flutter/material.dart';

class FixOverflowRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? maxWidth;
  final bool clipContent;

  const FixOverflowRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.maxWidth, // Optional maximum width constraint
    this.clipContent = false, // Whether to clip content that overflows
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxWidth = maxWidth ?? constraints.maxWidth;

        Widget content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.minWidth,
              maxWidth: effectiveMaxWidth,
            ),
            child: Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children:
                  clipContent
                      ? children.map((child) => ClipRect(child: child)).toList()
                      : children,
            ),
          ),
        );

        // Optionally apply clipping
        if (clipContent) {
          content = ClipRect(child: content);
        }

        return content;
      },
    );
  }
}

// Add a specialized version for chart usage
class ChartFixOverflowRow extends FixOverflowRow {
  const ChartFixOverflowRow({
    super.key,
    required super.children,
    super.mainAxisAlignment = MainAxisAlignment.start,
    super.crossAxisAlignment = CrossAxisAlignment.center,
    super.mainAxisSize = MainAxisSize.min,
    super.maxWidth,
    super.clipContent = true,
  });
}
