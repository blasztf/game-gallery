import 'dart:collection';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:game_gallery/conf.dart';
import 'package:game_gallery/fab.dart';
import 'package:game_gallery/item.dart';
import 'package:game_gallery/style.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

import 'data.dart';

class GameGalleryFormDialog extends StatefulWidget {
  const GameGalleryFormDialog(
      {super.key,
      this.onSubmit,
      this.children,
      required this.titleText,
      required this.submitText});

  final Function(HashMap<String, String>)? onSubmit;
  final List<Widget> Function(HashMap<String, String?>)? children;
  final String titleText;
  final String submitText;

  @override
  State<StatefulWidget> createState() => _GameGaleryFormDialogState();
}

class _GameGaleryFormDialogState extends State<GameGalleryFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final HashMap<String, String> _data = HashMap();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context),
      child: AlertDialog(
        title: Text(widget.titleText),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                widget.onSubmit?.call(_data);
              }
            },
            child: Text(widget.submitText),
          )
        ],
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.children?.call(_data) ?? [],
          ),
        ),
      ),
    );
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

  final double _spacing = 25.0;

  int get _sizeItem => _listItem.length;
  int get _crossAxisCount => _lastSize.width > 1440
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

  bool _scroll(int from, int to) {
    try {
      var context = GlobalObjectKey(_getItem(from)).currentContext!;
      double offset =
          ((to ~/ _crossAxisCount)).floor() * (context.size!.height + _spacing);
      _scrollController.animateTo(offset,
          duration: const Duration(seconds: 1), curve: Curves.decelerate);
      return true;
    } catch (e) {
      return false;
    }
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

    if (_lastPosition != newPosition && _scroll(_lastPosition, newPosition)) {
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
                          padding: EdgeInsets.all(_spacing),
                          mainAxisSpacing: _spacing,
                          crossAxisSpacing: _spacing,
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
                TextEditingController executableTextController =
                    TextEditingController();
                TextEditingController artworkTextController =
                    TextEditingController();
                showDialog(
                    context: context,
                    builder: (builderContext) {
                      return IgnorePointer(
                        ignoring: !_isActive,
                        child: GameGalleryFormDialog(
                          titleText: "Add new game",
                          submitText: "Add",
                          children: (data) => <Widget>[
                            TextFormField(
                              controller: executableTextController,
                              onTap: () {
                                _selectGameBinary((binaryFile) {
                                  try {
                                    executableTextController.text =
                                        binaryFile!.path!;
                                    data['executablePath'] =
                                        executableTextController.text;
                                  } catch (e) {
                                    showErrno(
                                        context, Errno.pickerFileNotSelected);
                                  }
                                });
                              },
                              decoration: const InputDecoration(
                                  hintText: "Click to select executable..."),
                            ),
                            TextFormField(
                              controller: artworkTextController,
                              onTap: () {
                                _selectCoverImage((coverFile) {
                                  try {
                                    artworkTextController.text =
                                        coverFile!.path!;
                                    data['artworkPath'] =
                                        artworkTextController.text;
                                  } catch (e) {
                                    showErrno(
                                        context, Errno.pickerFileNotSelected);
                                  }
                                });
                              },
                              decoration: const InputDecoration(
                                  hintText: "Click to select artwork..."),
                            )
                          ],
                          onSubmit: (data) {
                            try {
                              _addItem(GameGalleryData(
                                  executablePath: data['executablePath']!,
                                  coverPath: data['artworkPath']!));
                            } catch (e) {
                              showErrno(context, Errno.pickerFileNotSelected);
                            } finally {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      );
                    });
              },
              icon: const Icon(Icons.add),
            ),
            ActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: const Text("Do you want to remove this game?"),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("No"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _removeItem(_getItem(_lastPosition));
                          Navigator.pop(context);
                        },
                        child: const Text("Yes"),
                      )
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.remove),
            ),
            ActionButton(
              onPressed: () => _startGame(_getItem(_lastPosition)),
              icon: const Icon(Icons.play_arrow),
            ),
          ]),
        ));
  }
}
