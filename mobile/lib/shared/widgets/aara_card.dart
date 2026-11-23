import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class AaraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool hasGlow;

  const AaraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AaraColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasGlow ? AaraColors.champagne.withOpacity(0.4) : AaraColors.border,
          width: 1,
        ),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: AaraColors.champagne.withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
