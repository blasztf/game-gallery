import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:game_gallery/conf.dart';
import 'package:game_gallery/fab.dart';
import 'package:game_gallery/form.dart';
import 'package:game_gallery/item.dart';
import 'package:game_gallery/style.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

import 'data.dart';

class GameGalleryPageOverlay extends StatelessWidget {
  const GameGalleryPageOverlay({super.key, this.message = ""});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: mcgpalette0Accent.withOpacity(0.8),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            message,
            textScaleFactor: 1.5,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class GameGalleryPage extends StatefulWidget {
  const GameGalleryPage({super.key, required this.database});

  final GameObjectDatabase database;

  @override
  State<GameGalleryPage> createState() => _GameGalleryPageState();
}

class _GameGalleryPageState extends State<GameGalleryPage>
    with WidgetsBindingObserver, WindowListener {
  late Size _lastSize;
  List<GameObject> _listItem = [];

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

  Future<void> _addItem(final GameObject item) async {
    setState(() {
      _overlayState = _overlayEnabled;
      _isActive = false;
    });

    var artwork = await ImageBucket.instance.putArtwork(item.artwork);
    var banner = await ImageBucket.instance.putBanner(item.banner);
    var bigPicture = await ImageBucket.instance.putBigPicture(item.bigPicture);
    var logo = await ImageBucket.instance.putLogo(item.logo);

    var newItem = GameObject(item.title, item.executable, artwork, bigPicture,
        banner, logo, item.playTime.getDuration());

    await widget.database.save([newItem]);

    setState(() {
      _listItem.add(newItem);
      _overlayState = 0;
      _isActive = true;
    });
  }

  void _removeItem(final GameObject item) async {
    setState(() {
      _overlayState = _overlayEnabled;
      _isActive = false;
    });

    await widget.database.delete([item]);

    setState(() {
      _listItem.remove(item);
      _lastPosition = _lastPosition > 0 ? _lastPosition - 1 : 0;
      _overlayState = 0;
      _isActive = true;
    });
  }

  GameObject _getItem(int index) {
    return _listItem[index];
  }

  Size _calcDisplaySize() {
    return WidgetsBinding.instance.window.physicalSize /
        WidgetsBinding.instance.window.devicePixelRatio;
  }

  void _startGame(GameObject game) {
    setState(() {
      _overlayState = _overlayEnabled | _overlayGameRunning;
      _isActive = false;
    });

    game.play(callback: (gamePid) {
      widget.database.save([game]).then((affectedRows) {
        if (affectedRows > 0) {
          showMessage(
            context,
            "You have been played ${game.title} for total ${game.playTime.hours} hours ${game.playTime.minutes} minutes ${game.playTime.seconds} seconds.",
          ).then(
            (value) => setState(() {
              _isActive = true;
            }),
          );
        }
      });

      setState(() {
        _overlayState = 0;
      });
    });
  }

  void _showDialogRemoveItem() {
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
  }

  void _showDialogAddForm({Bundle? initialValue}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (builderContext) {
        return IgnorePointer(
          ignoring: !_isActive,
          child: AlertDialog(
            title: const Text("Add new game"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height / 2,
              child: GameAddForm(
                initialValue: initialValue,
                onCancel: () {
                  Navigator.pop(context);
                },
                onSubmit: (data) async {
                  if (context.mounted) Navigator.pop(context);
                  await _addItem(GameObject.build(data.flatten()));
                },
              ),
            ),
          ),
        );
      },
    );
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

    _lastSize = _calcDisplaySize();

    _gamepadController.buttonsMapping = {
      ControllerButton.DPAD_LEFT: () => _movePointer('left'),
      ControllerButton.DPAD_RIGHT: () => _movePointer('right'),
      ControllerButton.DPAD_UP: () => _movePointer('up'),
      ControllerButton.DPAD_DOWN: () => _movePointer('down'),
      ControllerButton.START: () => _startGame(_getItem(_lastPosition)),
      ControllerButton.Y_BUTTON: () =>
          (Navigator.canPop(context)) ? Navigator.pop(context) : null,
    };

    _gamepadController.listen();

    WindowManager.instance.addListener(this);
    WidgetsBinding.instance.addObserver(this);

    widget.database.load().then((value) {
      setState(() {
        _listItem = value;
      });
    });
  }

  @override
  void dispose() {
    WindowManager.instance.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !_isActive,
      child: Stack(
        children: [
          Scaffold(
            body: DropTarget(
              onDragDone: (detail) {
                if (detail.files.length > 1) {
                  showErrno(context, Errno.dragAndDropMultipleItems);
                } else {
                  Bundle initialValue = Bundle();
                  initialValue.putString('executable', detail.files[0].path);
                  _showDialogAddForm(initialValue: initialValue);
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
                child: AlignedGridView.count(
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
                  ),
                ),
              ),
            ),
            floatingActionButton: ExpandableFab(distance: 112.0, children: [
              ActionButton(
                onPressed: _showDialogAddForm,
                icon: const Icon(Icons.add),
              ),
              ActionButton(
                onPressed: _showDialogRemoveItem,
                icon: const Icon(Icons.remove),
              ),
              ActionButton(
                onPressed: () => _startGame(_getItem(_lastPosition)),
                icon: const Icon(Icons.play_arrow),
              ),
            ]),
          ),
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
      ),
    );
  }
}
