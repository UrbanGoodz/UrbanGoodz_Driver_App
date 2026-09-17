import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// One pill shape for every inline status/info badge in the app --
/// distance, open/closed, discount, item count, and so on. Before this,
/// store_card.dart alone hand-rolled three near-identical `Container` +
/// `BoxDecoration` pills, each with its own padding and radius; other
/// screens each had their own version too. Net new, additive: nothing is
/// forced onto this yet, it's adopted call site by call site.
class StatusChip extends StatelessWidget {
  final Widget? leading;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool bold;
  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.leading,
    this.bold = true,
  });

  /// A solid, filled pill -- for a call to action or a strong status like
  /// "20% off". [color] defaults to the theme's brand primary.
  factory StatusChip.solid(BuildContext context, {required String label, Color? color, Widget? leading}) {
    return StatusChip(
      label: label,
      backgroundColor: color ?? Theme.of(context).primaryColor,
      foregroundColor: Theme.of(context).cardColor,
      leading: leading,
    );
  }

  /// A quiet, tinted pill -- for supporting info like distance or item
  /// count that shouldn't compete with the card's real content.
  factory StatusChip.subtle(BuildContext context, {required String label, Widget? leading, Color? textColor}) {
    return StatusChip(
      label: label,
      backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.15),
      foregroundColor: textColor ?? Theme.of(context).textTheme.bodyLarge!.color!,
      leading: leading,
      bold: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        ],
        Text(
          label,
          style: (bold ? robotoBold : robotoMedium).copyWith(color: foregroundColor, fontSize: Dimensions.fontSizeSmall),
        ),
      ]),
    );
  }
}
