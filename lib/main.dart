import 'dart:io';
import 'package:path/path.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:game_gallery/app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  prepareWorkingDirectory();
  runApp(const GameGalleryApp());
  doWhenWindowReady(() {
    appWindow.minSize = const Size(480, 640);
    appWindow.size = const Size(640, 480);
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

void prepareWorkingDirectory() {
  String dir = join(Directory.current.path, 'images');
  File(join(dir, 'artwork')).createSync(recursive: true);
  File(join(dir, 'banner')).createSync(recursive: true);
  File(join(dir, 'big_picture')).createSync(recursive: true);
  File(join(dir, 'logo')).createSync(recursive: true);
}
