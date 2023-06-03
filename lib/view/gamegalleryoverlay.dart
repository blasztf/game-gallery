import 'package:flutter/material.dart';
import 'package:mangw/style.dart';

class GameGalleryOverlay extends StatelessWidget {
  const GameGalleryOverlay({super.key, this.message = ""});
  final double themeColorOpacity = 0.8;
  final double overlayMessageScale = 1.5;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: mcgpalette0Accent.withOpacity(themeColorOpacity),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            message,
            textScaleFactor: overlayMessageScale,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
