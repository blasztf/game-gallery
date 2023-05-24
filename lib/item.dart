import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game_gallery/data.dart';
import 'package:game_gallery/img.dart';
import 'package:game_gallery/style.dart';

class GameGalleryItem extends StatelessWidget {
  const GameGalleryItem({
    super.key,
    required this.data,
    required this.isSelected,
    this.onPress,
    this.onLongPress,
    this.onHover,
  });

  final GameObject data;
  final bool isSelected;
  final Function(GameObject)? onPress;
  final Function(GameObject)? onLongPress;
  final Function(GameObject)? onHover;

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
              child: Image.file(
                  fit: BoxFit.fill,
                  File(ImageBucket.instance.getArtwork(data.artwork)))),
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
