import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

enum AaraButtonVariant { primary, secondary, outline, danger }

class AaraButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AaraButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;

  const AaraButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AaraButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            decoration: _getBoxDecoration(),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: _getTextColor()),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: AaraTypography.labelLarge.copyWith(color: _getTextColor()),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBoxDecoration() {
    switch (variant) {
      case AaraButtonVariant.primary:
        return BoxDecoration(
          color: onPressed == null ? AaraColors.cardBorder : AaraColors.plumViolet,
          borderRadius: BorderRadius.circular(26),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: AaraColors.plumViolet.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        );
      case AaraButtonVariant.secondary:
        return BoxDecoration(
          color: AaraColors.softLavender,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AaraColors.border, width: 1),
        );
      case AaraButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AaraColors.plumViolet, width: 1.5),
        );
      case AaraButtonVariant.danger:
        return BoxDecoration(
          color: AaraColors.error,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AaraColors.error.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  Color _getTextColor() {
    if (onPressed == null) return AaraColors.textSecondary;
    switch (variant) {
      case AaraButtonVariant.primary:
        return Colors.white; // Solid plum button with crisp white text
      case AaraButtonVariant.secondary:
        return AaraColors.plumViolet;
      case AaraButtonVariant.outline:
        return AaraColors.plumViolet;
      case AaraButtonVariant.danger:
        return Colors.white; // Red button with white text
    }
  }
}
