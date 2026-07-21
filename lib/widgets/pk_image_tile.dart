import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';

class PkImageTile extends StatelessWidget {
  const PkImageTile({
    required this.label,
    required this.seed,
    super.key,
    this.size = 96,
    this.assetPath,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String label;
  final int seed;
  final double size;
  final String? assetPath;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.pkColors;
    final radius = context.pkRadius;
    final palette = colors.piecePalette;
    final background = palette[seed.abs() % palette.length];

    return Semantics(
      container: true,
      label: label,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius.card),
            border: Border.all(color: colors.outline, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius.card - 2),
            child: assetPath == null
                ? ExcludeSemantics(
                    child: Icon(
                      Icons.landscape_rounded,
                      color: colors.onSurface,
                      size: 40,
                    ),
                  )
                : Image.asset(
                    assetPath!,
                    fit: BoxFit.cover,
                    cacheWidth: cacheWidth,
                    cacheHeight: cacheHeight,
                    errorBuilder: (context, error, stackTrace) {
                      return ExcludeSemantics(
                        child: Icon(
                          Icons.landscape_rounded,
                          color: colors.onSurface,
                          size: 40,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
