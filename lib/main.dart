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
import 'dart:math';

void main() {
  runApp(const GameGalleryApp());
  doWhenWindowReady(() {
    const initialSize = Size(400, 640);
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

Future showMessage(BuildContext context, String message) async {
  ThemeData theme = Theme.of(context);
  return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
            backgroundColor: theme.primaryColor,
            titleTextStyle: theme.primaryTextTheme.titleMedium,
            contentTextStyle: theme.primaryTextTheme.bodyMedium,
            content: Text(message),
          ));
}

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

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
  });

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.secondary,
      elevation: 4.0,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: theme.colorScheme.onSecondary,
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: mcgpalette0,
            child: const Icon(Icons.settings),
          ),
        ),
      ),
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

  void start(Function(int) callback) async {
    ProcessResult p = await Process.run(executablePath, []);
    callback(p.pid);
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

class GameGalleryPageOverlay extends StatefulWidget {
  const GameGalleryPageOverlay({super.key, this.message = ""});

  final String message;

  @override
  State<StatefulWidget> createState() => _GameGalleryPageOverlayState();
}

class _GameGalleryPageOverlayState extends State<GameGalleryPageOverlay> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
          color: mcgpalette0Accent.withOpacity(0.8),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              widget.message,
              textScaleFactor: 1.5,
              style: const TextStyle(color: Colors.white),
            ),
          )),
    );
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
  List<GameGalleryData> _listItem = [];

  int _lastPosition = 0;
  bool _isActive = true;

  int _overlayState = 0;
  final int _overlayEnabled = 1;
  final int _overlayGameRunning = 2;
  final int _overlayFilePickerOpening = 4;
  final int _overlayFileDragging = 8;

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

  void _scroll(int from, int to) {
    try {
      var context = GlobalObjectKey(_getItem(from)).currentContext!;
      double offset =
          ((to ~/ _crossAxisCount)).floor() * (context.size?.height ?? 0);
      _scrollController.animateTo(offset,
          duration: const Duration(seconds: 1), curve: Curves.decelerate);
      // ignore: empty_catches
    } catch (e) {}
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
    if (!_isActive) return;

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
      _scroll(_lastPosition, newPosition);
      setState(() {
        _lastPosition = newPosition;
      });
    }
  }

  void _addItem(final GameGalleryData item) {
    setState(() {
      _listItem.add(item);
    });
    widget.storage.save(_listItem);
  }

  void _removeItem(final GameGalleryData item) {
    setState(() {
      _listItem.remove(item);
    });
    widget.storage.save(_listItem);
  }

  GameGalleryData _getItem(int index) {
    return _listItem[index];
  }

  void _openFilePicker() {
    setState(() {
      _overlayState = _overlayEnabled | _overlayFilePickerOpening;
      _isActive = false;
    });
  }

  void _closeFilePicker() {
    setState(() {
      _overlayState = 0;
      _isActive = true;
    });
  }

  void _selectCoverImage(
      void Function(PlatformFile? coverFile) onComplete) async {
    _openFilePicker();
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(dialogTitle: "Select cover image", type: FileType.image);

    onComplete(result?.files.single);

    _closeFilePicker();
  }

  void _selectGameBinary(
      void Function(PlatformFile? binaryFile) onComplete) async {
    _openFilePicker();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: "Select game binary",
        type: FileType.custom,
        allowedExtensions: ['exe']);

    onComplete(result?.files.single);

    _closeFilePicker();
  }

  Size _calcDisplaySize() {
    return WidgetsBinding.instance.window.physicalSize /
        WidgetsBinding.instance.window.devicePixelRatio;
  }

  void _startGame(GameGalleryData game) {
    setState(() {
      _overlayState = _overlayEnabled | _overlayGameRunning;
      _isActive = false;
    });

    var startTime = DateTime.now();
    game.start((gamePid) {
      var playDuration = DateTimeRange(start: startTime, end: DateTime.now())
          .duration
          .inSeconds;

      var playHours = playDuration ~/ 3600;
      var playMinutes = (playDuration - playHours * 3600) ~/ 60;
      var playSeconds = playDuration - (playHours * 3600) - (playMinutes * 60);

      showMessage(context,
              "You have been playing for $playHours hours $playMinutes minutes $playSeconds seconds.")
          .then((value) => setState(() {
                _isActive = true;
              }));

      setState(() {
        _overlayState = 0;
      });
    });
  }

  @override
  void didChangeMetrics() {
    setState(() {
      _lastSize = _calcDisplaySize();
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
  void initState() {
    super.initState();
    widget.storage.load().then((value) {
      setState(() {
        _listItem = value;
      });
    });

    _lastSize = _calcDisplaySize();
    WidgetsBinding.instance.addObserver(this);

    _gamepadController.buttonsMapping = {
      ControllerButton.DPAD_LEFT: () => _movePointer('left'),
      ControllerButton.DPAD_RIGHT: () => _movePointer('right'),
      ControllerButton.DPAD_UP: () => _movePointer('up'),
      ControllerButton.DPAD_DOWN: () => _movePointer('down'),
      ControllerButton.START: () => _startGame(_getItem(_lastPosition))
    };

    _gamepadController.listen();

    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing: !_isActive,
        child: Scaffold(
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
                  _overlayState = _overlayEnabled | _overlayFileDragging;
                });
              },
              onDragExited: (detail) {
                setState(() {
                  _overlayState = 0;
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
                                key: _lastPosition == index
                                    ? GlobalObjectKey(_getItem(index))
                                    : null,
                                data: _getItem(index),
                                isSelected: _lastPosition == index,
                                onPress: (data) {
                                  setState(() {
                                    _lastPosition = index;
                                  });
                                },
                                onLongPress: (data) {
                                  setState(() {
                                    _lastPosition = index;
                                  });
                                },
                              )),
                      if (_overlayState & _overlayEnabled != 0)
                        GameGalleryPageOverlay(
                          message: _overlayState & _overlayFileDragging != 0
                              ? "Drag and drop file to add new item"
                              : _overlayState & _overlayFilePickerOpening != 0
                                  ? "Pick a file..."
                                  : _overlayState & _overlayGameRunning != 0
                                      ? "Game is running..."
                                      : "",
                        )
                    ],
                  ))),
          floatingActionButton: ExpandableFab(distance: 112.0, children: [
            ActionButton(
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
              icon: const Icon(Icons.add),
            ),
            ActionButton(
              onPressed: () => _removeItem(_getItem(_lastPosition)),
              icon: const Icon(Icons.remove),
            ),
            ActionButton(
              onPressed: () => _startGame(_getItem(_lastPosition)),
              icon: const Icon(Icons.play_arrow),
            ),
            ActionButton(
              onPressed: () => _startGame(_getItem(_lastPosition)),
              icon: const Icon(Icons.video_call),
            ),
          ]),
        ));
  }
}

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
