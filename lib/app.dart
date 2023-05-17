import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:game_gallery/data.dart';
import 'package:game_gallery/page.dart';
import 'package:game_gallery/style.dart';

final buttonColors = WindowButtonColors(
    mouseOver: mcgpalette0Accent.shade500,
    mouseDown: mcgpalette0.shade500,
    iconNormal: Colors.white60,
    iconMouseOver: Colors.white,
    iconMouseDown: Colors.white60);

final closeButtonColors = WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: Colors.white60,
    iconMouseOver: Colors.white);

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

class GameGalleryApp extends StatelessWidget {
  const GameGalleryApp({super.key});

  final String title = "Game Gallery";

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    ThemeData theme = ThemeData(primarySwatch: mcgpalette0);
    theme = theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(secondary: mcgpalette0Accent));
    return MaterialApp(
        theme: theme,
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          mcgpalette0Accent.shade500,
                          mcgpalette0.shade500,
                        ],
                        tileMode: TileMode.clamp)),
                child: MoveWindow()),
            actions: const [WindowButtons()],
            title: Text(title),
          ),
          body: const GameGalleryPage(
            storage: GameGalleryStorage(),
          ),
        ));
  }
}
