import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class ProfileImageView extends StatelessWidget {
  final String? imageUrl;
  final String fallbackInitial;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProfileImageView({
    super.key,
    required this.imageUrl,
    this.fallbackInitial = 'U',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildFallback(radius);
    }

    final trimmed = imageUrl!.trim();

    // Base64 Data URL (e.g. data:image/jpeg;base64,...)
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64Data = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        final bytes = base64Decode(base64Data);
        return ClipRRect(
          borderRadius: radius,
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildFallback(radius),
          ),
        );
      } catch (_) {
        return _buildFallback(radius);
      }
    }

    // Local Asset (e.g. assets/telegram/...)
    if (trimmed.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          trimmed,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(radius),
        ),
      );
    }

    // Direct HTTP/HTTPS Network URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          trimmed,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: AaraColors.surfaceCard,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AaraColors.champagneLight,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildFallback(radius),
        ),
      );
    }

    return _buildFallback(radius);
  }

  Widget _buildFallback(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AaraColors.surfaceCard,
        borderRadius: radius,
        border: Border.all(color: AaraColors.border),
      ),
      child: Center(
        child: Text(
          fallbackInitial.isNotEmpty ? fallbackInitial[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: (height != null && height! < 60) ? 20 : 36,
            fontWeight: FontWeight.bold,
            color: AaraColors.champagneLight,
          ),
        ),
      ),
    );
  }
}
