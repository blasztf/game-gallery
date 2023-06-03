import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangw/complement/ifc.dart';
import 'package:mangw/style.dart';

import '../error/errno.dart';

class GalleryCard extends StatelessWidget with InternetFileCheck {
  const GalleryCard({
    super.key,
    required this.image,
    required this.isSelected,
    this.onPress,
    this.onLongPress,
    this.onHover,
  });

  final String image;
  final bool isSelected;
  final Function(String)? onPress;
  final Function(String)? onLongPress;
  final Function(String)? onHover;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8.0,
      color: mcgpalette0Accent,
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color: Colors.amber.shade900.withAlpha(isSelected ? 255 : 0),
              blurRadius: 6.0,
              spreadRadius: 3.0)
        ]),
        child: InkWell(
          onTap: () => onPress?.call(image),
          onLongPress: () => onLongPress?.call(image),
          onHover: (isHover) => isHover ? onHover?.call(image) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: isFileFromInternet(image)
                ? Image.network(
                    image,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(Errno.imageNotFound.message);
                    },
                  )
                : Image.file(
                    File(image),
                    fit: BoxFit.fill,
                  ),
          ),
        ),
      ),
    );
  }
}
