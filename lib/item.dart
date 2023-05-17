import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game_gallery/data.dart';
import 'package:game_gallery/style.dart';

class GameGalleryItem extends StatefulWidget {
  const GameGalleryItem(
      {super.key,
      required this.data,
      required this.isSelected,
      this.onPress,
      this.onLongPress,
      this.onHover});

  final GameGalleryData data;
  final bool isSelected;
  final Function(GameGalleryData)? onPress;
  final Function(GameGalleryData)? onLongPress;
  final Function(GameGalleryData)? onHover;

  @override
  State<GameGalleryItem> createState() => _GameGalleryItemState();
}

class _GameGalleryItemState extends State<GameGalleryItem> {
  @override
  Widget build(BuildContext context) {
    return Material(
        elevation: 8.0,
        color: mcgpalette0Accent,
        child: Container(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  color: Colors.amber.shade900
                      .withAlpha(widget.isSelected ? 255 : 0),
                  blurRadius: 6.0,
                  spreadRadius: 3.0)
            ]),
            child: InkWell(
              onTap: () => widget.onPress?.call(widget.data),
              onLongPress: () => widget.onLongPress?.call(widget.data),
              onHover: (isHover) =>
                  isHover ? widget.onHover?.call(widget.data) : null,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                      fit: BoxFit.fill, File(widget.data.coverPath))),
            )));
  }
}
