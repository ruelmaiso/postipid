import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class ItemImageThumb extends StatelessWidget {
  const ItemImageThumb({
    super.key,
    required this.imageFuture,
    this.size = 68,
    this.radius = 22,
    this.icon = Icons.inventory_2_rounded,
    this.backgroundColor,
  });

  final Future<File?> imageFuture;
  final double size;
  final double radius;
  final IconData icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final fill = backgroundColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppPalette.nightSurfaceAlt
            : AppPalette.surfaceTint);

    return FutureBuilder<File?>(
      future: imageFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            image: file != null
                ? DecorationImage(
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: file == null
              ? Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        );
      },
    );
  }
}
