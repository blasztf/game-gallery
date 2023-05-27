import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game_gallery/style.dart';

class GalleryItem extends StatelessWidget {
  const GalleryItem({
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

  // Check if file from local or internet
  bool _isFileFromInternet(String path) {
    return path.startsWith(RegExp(r'https?://'));
  }

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
            child: _isFileFromInternet(image)
                ? Image.network(
                    image,
                    fit: BoxFit.fill,
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

class ImageChooserItem extends StatelessWidget {
  const ImageChooserItem({
    super.key,
    required this.data,
    required this.isSelected,
    this.onPress,
    this.onLongPress,
    this.onHover,
  });

  final String data;
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
          onTap: () => onPress?.call(data),
          onLongPress: () => onLongPress?.call(data),
          onHover: (isHover) => isHover ? onHover?.call(data) : null,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(fit: BoxFit.fill, data)),
        ),
      ),
    );
  }
}
