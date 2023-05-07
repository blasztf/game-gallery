import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

void main() {
  runApp(const GameGalleryApp());
  doWhenWindowReady(() {
    const initialSize = Size(400, 320);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class Errno {
  Errno({required this.id, required this.message});

  final String id;
  final String message;

  static final Errno dragAndDropMultipleItems =
      Errno(id: 'E001', message: "Only supports 1 file at the moment!");
  static final Errno pickerFileNotSelected =
      Errno(id: 'E002', message: "No file selected!");
}

class Config {
  static final String dataJsonPath =
      "Game_Gallery${Platform.pathSeparator}data.json";
}

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

const MaterialColor mcgpalette0 =
    MaterialColor(_mcgpalette0PrimaryValue, <int, Color>{
  50: Color(0xFFE3E4E4),
  100: Color(0xFFB9BABC),
  200: Color(0xFF8B8D90),
  300: Color(0xFF5D5F64),
  400: Color(0xFF3A3C42),
  500: Color(_mcgpalette0PrimaryValue),
  600: Color(0xFF14171D),
  700: Color(0xFF111318),
  800: Color(0xFF0D0F14),
  900: Color(0xFF07080B),
});
const int _mcgpalette0PrimaryValue = 0xFF171A21;

const MaterialColor mcgpalette0Accent =
    MaterialColor(_mcgpalette0AccentValue, <int, Color>{
  50: Color(0xFFE4E5E7),
  100: Color(0xFFBBBFC3),
  200: Color(0xFF8D949C),
  300: Color(0xFF5F6974),
  400: Color(0xFF3D4856),
  500: Color(_mcgpalette0AccentValue),
  600: Color(0xFF182432),
  700: Color(0xFF141E2B),
  800: Color(0xFF101824),
  900: Color(0xFF080F17),
});
const int _mcgpalette0AccentValue = 0xFF1B2838;

void showErrno(BuildContext context, Errno errno) {
  String errnoId = errno.id;

  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text("ERROR: $errnoId"),
            content: Text(errno.message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, "OK"),
                  child: const Text("OK"))
            ],
          ));
}

void showMessage(BuildContext context, String message) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
          content: Text(message),
        ));

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

class GameGalleryStorage {
  const GameGalleryStorage();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    final dataJsonPath = Config.dataJsonPath;
    return File('$path${Platform.pathSeparator}$dataJsonPath');
  }

  Future<List<GameGalleryData>> load() async {
    try {
      final File file = await _localFile;
      final contents = await file.readAsString();
      final parsed = jsonDecode(contents).cast<Map<String, dynamic>>();
      return parsed
          .map<GameGalleryData>((json) => GameGalleryData.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> save(List<GameGalleryData> data) async {
    try {
      final file = await _localFile;
      final parsed = data.map((item) => GameGalleryData.toJson(item)).toList();
      final String contents = jsonEncode(parsed);

      file.writeAsString(contents);
      return true;
    } catch (e) {
      // If encountering an error, return 0
      return false;
    }
  }
}

class GameGalleryData {
  final String executablePath;
  final String coverPath;

  static final GameGalleryData invalid =
      GameGalleryData(executablePath: '', coverPath: '');

  static bool isValid(GameGalleryData data) => data == GameGalleryData.invalid;

  GameGalleryData({required this.executablePath, required this.coverPath});

  factory GameGalleryData.fromJson(Map<String, dynamic> json) {
    return GameGalleryData(
        executablePath: json['executablePath'] as String,
        coverPath: json['coverPath'] as String);
  }

  static Map<String, dynamic> toJson(GameGalleryData value) {
    return {
      'executablePath': value.executablePath,
      'coverPath': value.coverPath
    };
  }

  void start() async {
    await Process.run(executablePath, []);
  }
}

class GameGalleryApp extends StatelessWidget {
  const GameGalleryApp({super.key});

  final String title = "Big Picture";

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

class GameGalleryPage extends StatefulWidget {
  const GameGalleryPage({super.key, required this.storage});

  final GameGalleryStorage storage;

  @override
  State<GameGalleryPage> createState() => _GameGalleryPageState();
}

class _GameGalleryPageState extends State<GameGalleryPage>
    with WidgetsBindingObserver, WindowListener {
  late Size _lastSize;
  bool _isDragging = false;
  List<GameGalleryData> _listItem = [];
  int _lastPosition = 0;

  int get _sizeItem => _listItem.length;
  int get _crossAxisCount => _lastSize.width > 1920
      ? 8
      : _lastSize.width > 960
          ? 6
          : _lastSize.width > 640
              ? 4
              : _lastSize.width > 480
                  ? 2
                  : 1;

  final Controller _gamepadController = Controller(index: 0);
  final ScrollController _scrollController = ScrollController();

  void _scrollTo(int index) {
    _scrollController.jumpTo(_lastSize.height * (_crossAxisCount % index));
  }

  int _movePointerUp() {
    int newPosition = _lastPosition - _crossAxisCount;
    return newPosition >= 0 ? newPosition : _lastPosition;
  }

  int _movePointerDown() {
    int newPosition = _lastPosition + _crossAxisCount;
    return newPosition < _sizeItem ? newPosition : _lastPosition;
  }

  int _movePointerLeft() {
    int newPosition = _lastPosition - 1;
    return newPosition >= 0 ? newPosition : _lastPosition;
  }

  int _movePointerRight() {
    int newPosition = _lastPosition + 1;
    return newPosition < _sizeItem ? newPosition : _lastPosition;
  }

  void _movePointer(String key) {
    int newPosition = _lastPosition;
    switch (key) {
      case 'up':
        newPosition = _movePointerUp();
        break;
      case 'down':
        newPosition = _movePointerDown();
        break;
      case 'left':
        newPosition = _movePointerLeft();
        break;
      case 'right':
        newPosition = _movePointerRight();
        break;
      default:
    }

    if (_lastPosition != newPosition) {
      setState(() {
        _lastPosition = newPosition;
        _scrollTo(_lastPosition);
      });
    }
  }

  void _addItem(final GameGalleryData item) {
    setState(() {
      _listItem.add(item);
      widget.storage.save(_listItem);
    });
  }

  GameGalleryData _getItem(int index) {
    return _listItem[index];
  }

  void _selectCoverImage(
      void Function(PlatformFile? coverFile) onComplete) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(dialogTitle: "Select cover image", type: FileType.image);

    onComplete(result?.files.single);
  }

  void _selectGameBinary(
      void Function(PlatformFile? binaryFile) onComplete) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: "Select game binary",
        type: FileType.custom,
        allowedExtensions: ['exe']);

    onComplete(result?.files.single);
  }

  void _calcDisplaySize() {
    _lastSize = WidgetsBinding.instance.window.physicalSize /
        WidgetsBinding.instance.window.devicePixelRatio;
  }

  @override
  void initState() {
    super.initState();
    widget.storage.load().then((value) {
      setState(() {
        _listItem = value;
      });
    });

    _calcDisplaySize();
    WidgetsBinding.instance.addObserver(this);

    _gamepadController.buttonsMapping = {
      ControllerButton.DPAD_LEFT: () => _movePointer('left'),
      ControllerButton.DPAD_RIGHT: () => _movePointer('right'),
      ControllerButton.DPAD_UP: () => _movePointer('up'),
      ControllerButton.DPAD_DOWN: () => _movePointer('down'),
      ControllerButton.START: () => _getItem(_lastPosition).start()
    };

    _gamepadController.listen();

    windowManager.addListener(this);

    _scrollController.addListener(() {});
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {
      _calcDisplaySize();
    });
  }

  @override
  void onWindowBlur() {
    _gamepadController.activated = false;
    super.onWindowBlur();
  }

  @override
  void onWindowFocus() {
    _gamepadController.activated = true;
    super.onWindowFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: DropTarget(
            onDragDone: (detail) {
              if (detail.files.length > 1) {
                showErrno(context, Errno.dragAndDropMultipleItems);
              } else {
                _selectCoverImage((coverFile) {
                  if (coverFile?.path != null) {
                    _addItem(GameGalleryData(
                        executablePath: detail.files[0].path,
                        coverPath: coverFile?.path ?? ''));
                  } else {
                    showErrno(context, Errno.pickerFileNotSelected);
                  }
                });
              }
            },
            onDragEntered: (detail) {
              setState(() {
                _isDragging = true;
              });
            },
            onDragExited: (detail) {
              setState(() {
                _isDragging = false;
              });
            },
            child: Container(
                color: mcgpalette0Accent,
                child: Stack(
                  children: [
                    AlignedGridView.count(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(25.0),
                        mainAxisSpacing: 25.0,
                        crossAxisSpacing: 50.0,
                        crossAxisCount: _crossAxisCount,
                        itemCount: _sizeItem,
                        itemBuilder: (BuildContext context, int index) =>
                            GameGalleryItem(
                              data: _getItem(index),
                              isSelected: _lastPosition == index,
                              onTap: (data) => data.start(),
                            )),
                    if (_isDragging)
                      Positioned.fill(
                        child: Container(
                            color: mcgpalette0Accent.withOpacity(0.8),
                            child: const Align(
                              alignment: Alignment.center,
                              child: Text(
                                "Drag and drop file to add new item",
                                textScaleFactor: 1.5,
                                style: TextStyle(color: Colors.white),
                              ),
                            )),
                      ),
                  ],
                ))),
        floatingActionButton: FloatingActionButton(
          backgroundColor: mcgpalette0,
          onPressed: () {
            _selectGameBinary((binaryFile) {
              if (binaryFile?.path != null) {
                _selectCoverImage((coverFile) {
                  if (coverFile?.path != null) {
                    _addItem(GameGalleryData(
                        executablePath: binaryFile?.path ?? '',
                        coverPath: coverFile?.path ?? ''));
                  } else {
                    showErrno(context, Errno.pickerFileNotSelected);
                  }
                });
              } else {
                showErrno(context, Errno.pickerFileNotSelected);
              }
            });
          },
          tooltip: 'Add item',
          child: const Icon(Icons.add),
        ));
  }
}

class GameGalleryItem extends StatefulWidget {
  const GameGalleryItem(
      {super.key,
      required this.data,
      required this.isSelected,
      required this.onTap});

  final GameGalleryData data;
  final bool isSelected;
  final Function(GameGalleryData) onTap;

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
                  color: Colors.amber.shade800
                      .withAlpha(widget.isSelected ? 255 : 0),
                  blurRadius: 6.0,
                  spreadRadius: 0.0)
            ]),
            child: InkWell(
              onTap: () => widget.onTap(widget.data),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                      fit: BoxFit.fill, File(widget.data.coverPath))),
            )));
  }
}
