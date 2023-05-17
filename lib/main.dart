import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:game_gallery/app.dart';

void main() {
  runApp(const GameGalleryApp());
  doWhenWindowReady(() {
    appWindow.minSize = const Size(480, 640);
    appWindow.size = const Size(640, 480);
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}
