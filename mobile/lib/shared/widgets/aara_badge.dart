import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class AaraAllowanceBadge extends StatelessWidget {
  final int remaining;
  final int total;
  final bool hasActivePass;

  const AaraAllowanceBadge({
    super.key,
    required this.remaining,
    this.total = 5,
    this.hasActivePass = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hasActivePass) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AaraColors.softLavender,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AaraColors.plumViolet, width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 15, color: AaraColors.plumViolet),
              const SizedBox(width: 4),
              Text(
                'PASS ACTIVE',
                style: AaraTypography.labelSmall.copyWith(
                  color: AaraColors.plumViolet,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AaraColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AaraColors.plumViolet.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(total, (index) {
                final isFilled = index < remaining;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AaraColors.plumViolet : AaraColors.border,
                  ),
                );
              }),
            ),
            const SizedBox(width: 7),
            Text(
              '$remaining of $total Free Calls',
              style: AaraTypography.labelSmall.copyWith(
                color: AaraColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
