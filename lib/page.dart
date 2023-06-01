import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:game_gallery/conf.dart';
import 'package:game_gallery/fab.dart';
import 'package:game_gallery/form.dart';
import 'package:game_gallery/img.dart';
import 'package:game_gallery/item.dart';
import 'package:game_gallery/style.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

import 'data.dart';

abstract class GalleryPageAdapter<T> {
  T getItem(int index);
  String getItemImage(int index);
  int getSize();
  void onItemTap(T item) {}
}

class GalleryPageController extends ChangeNotifier {
  GlobalKey? _item;
  int _crossAxisCount = 0;
  double _spacing = 0;
  ScrollController? _scrollController;
  int _highlightIndex = 0;

  int get highlightPosition => _highlightIndex;

  int getCrossAxisCount() {
    return _crossAxisCount;
  }

  bool scrollTo(int index) {
    try {
      var context = _item!.currentContext!;
      double offset = ((index ~/ _crossAxisCount)).floor() *
          (context.size!.height + _spacing);
      _scrollController?.animateTo(offset,
          duration: const Duration(seconds: 1), curve: Curves.decelerate);
      return true;
    } catch (e) {
      return false;
    }
  }

  void highlightItem(int index) {
    _highlightIndex = index;
    notifyListeners();
  }

  ScrollController setScroller(ScrollController scroller) {
    return _scrollController = scroller;
  }

  void setFactor(GlobalKey activeItemKey, int crossAxisCount, double spacing) {
    _item = activeItemKey;
    _crossAxisCount = crossAxisCount;
    _spacing = spacing;
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.adapter, this.controller});

  final GalleryPageAdapter adapter;
  final GalleryPageController? controller;

  @override
  State<StatefulWidget> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> with WidgetsBindingObserver {
  late Size _lastSize;
  final double _spacing = 25.0;

  int get _crossAxisCount => _lastSize.width > 1440
      ? 8
      : _lastSize.width > 960
          ? 6
          : _lastSize.width > 640
              ? 4
              : _lastSize.width > 480
                  ? 2
                  : 1;

  late final ScrollController _scrollController;

  Size _calcDisplaySize() {
    return WidgetsBinding.instance.window.physicalSize /
        WidgetsBinding.instance.window.devicePixelRatio;
  }

  @override
  void didChangeMetrics() {
    setState(() {
      _lastSize = _calcDisplaySize();
    });
  }

  @override
  void initState() {
    super.initState();
    _lastSize = _calcDisplaySize();
    _scrollController = ScrollController();
    widget.controller?.setScroller(_scrollController);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mcgpalette0Accent,
      child: AlignedGridView.count(
          controller: widget.controller?._scrollController,
          padding: EdgeInsets.all(_spacing),
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          crossAxisCount: _crossAxisCount,
          itemCount: widget.adapter.getSize(),
          itemBuilder: (BuildContext itemBuilderContext, int index) {
            return AnimatedBuilder(
                animation: widget.controller ?? GalleryPageController(),
                builder: (context, child) {
                  GlobalObjectKey? activeItemKey;
                  bool isSelected = widget.controller?._highlightIndex == index;
                  if (isSelected) {
                    activeItemKey =
                        GlobalObjectKey(widget.adapter.getItem(index));
                    widget.controller?.setFactor(
                      activeItemKey,
                      _crossAxisCount,
                      _spacing,
                    );
                  }
                  return GalleryItem(
                    key: activeItemKey,
                    image: widget.adapter.getItemImage(index),
                    isSelected: isSelected,
                    onPress: (data) {
                      widget.adapter.onItemTap
                          .call(widget.adapter.getItem(index));
                      widget.controller?.highlightItem(index);
                    },
                    onLongPress: (data) {
                      widget.adapter.onItemTap
                          .call(widget.adapter.getItem(index));
                      widget.controller?.highlightItem(index);
                    },
                  );
                });
          }),
    );
  }
}

class GameGalleryAdapter extends GalleryPageAdapter<GameObject> {
  GameGalleryAdapter._(this._list, this._onTap);

  factory GameGalleryAdapter(
          {required List<GameObject> list, Function(GameObject)? onItemTap}) =>
      GameGalleryAdapter._(list, onItemTap);

  final List<GameObject> _list;
  final Function(GameObject)? _onTap;

  @override
  GameObject getItem(int index) {
    return _list[index];
  }

  @override
  String getItemImage(int index) {
    return ImageBucket.instance.getArtwork(_list[index].artwork);
  }

  @override
  int getSize() {
    return _list.length;
  }

  @override
  void onItemTap(GameObject item) {
    _onTap?.call(item);
  }
}

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
  List<GameObject> _listItem = [];

  bool _isActive = true;

  int _overlayState = 0;
  final int _overlayEnabled = 1;
  final int _overlayGameRunning = 2;
  final int _overlayFilePickerOpening = 4;
  final int _overlayFileDragging = 8;

  final Controller _gamepadController = Controller(index: 0);
  final GalleryPageController _gpController = GalleryPageController();

  int get _sizeItem => _listItem.length;

  int _movePointerUp() {
    int newPosition =
        _gpController.highlightPosition - _gpController.getCrossAxisCount();
    return newPosition >= 0 ? newPosition : _gpController.highlightPosition;
  }

  int _movePointerDown() {
    int newPosition =
        _gpController.highlightPosition + _gpController.getCrossAxisCount();
    return newPosition < _sizeItem
        ? newPosition
        : _gpController.highlightPosition;
  }

  int _movePointerLeft() {
    int newPosition = _gpController.highlightPosition - 1;
    return newPosition >= 0 ? newPosition : _gpController.highlightPosition;
  }

  int _movePointerRight() {
    int newPosition = _gpController.highlightPosition + 1;
    return newPosition < _sizeItem
        ? newPosition
        : _gpController.highlightPosition;
  }

  void _movePointer(String key) {
    if (!_isActive) return;

    int newPosition = _gpController.highlightPosition;
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

    if (_gpController.highlightPosition != newPosition &&
        _gpController.scrollTo(newPosition)) {
      _gpController.highlightItem(newPosition);
    }
  }

  Future<void> _saveItem(
      final GameObject item, final GameObject? oldItem) async {
    setState(() {
      _overlayState = _overlayEnabled;
      _isActive = false;
    });

    var artwork = await ImageBucket.instance.putArtwork(item.artwork);
    var banner = await ImageBucket.instance.putBanner(item.banner);
    var bigPicture = await ImageBucket.instance.putBigPicture(item.bigPicture);
    var logo = await ImageBucket.instance.putLogo(item.logo);

    var newItem = GameObject(item.title, item.executable, artwork, bigPicture,
        banner, logo, item.playTime.getDuration(),
        id: item.id);

    await widget.database.save([newItem]);

    if (_listItem.contains(oldItem)) {
      _listItem[_listItem.indexOf(oldItem!)] = newItem;
    } else {
      _listItem.add(newItem);
    }

    setState(() {
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
    _listItem.remove(item);

    _gpController.highlightItem(_gpController.highlightPosition > 0
        ? _gpController.highlightPosition - 1
        : 0);

    setState(() {
      _overlayState = 0;
      _isActive = true;
    });
  }

  GameObject _getItem(int index) {
    return _listItem[index];
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
              _removeItem(_getItem(_gpController.highlightPosition));
              Navigator.pop(context);
            },
            child: const Text("Yes"),
          )
        ],
      ),
    );
  }

  void _showDialogSaveForm({required String title, GameObject? initialValue}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (builderContext) {
        return IgnorePointer(
          ignoring: !_isActive,
          child: AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height / 2,
              child: GameSaveForm(
                initialValue: initialValue,
                onCancel: () {
                  Navigator.pop(context);
                },
                onSubmit: (data) async {
                  if (context.mounted) Navigator.pop(context);
                  await _saveItem(data, initialValue);
                },
              ),
            ),
          ),
        );
      },
    );
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

    _gamepadController.buttonsMapping = {
      ControllerButton.DPAD_LEFT: () => _movePointer('left'),
      ControllerButton.DPAD_RIGHT: () => _movePointer('right'),
      ControllerButton.DPAD_UP: () => _movePointer('up'),
      ControllerButton.DPAD_DOWN: () => _movePointer('down'),
      ControllerButton.START: () =>
          _startGame(_getItem(_gpController.highlightPosition)),
      ControllerButton.Y_BUTTON: () =>
          (Navigator.canPop(context)) ? Navigator.pop(context) : null,
    };

    _gamepadController.listen();

    WindowManager.instance.addListener(this);

    widget.database.load().then((value) {
      setState(() {
        _listItem = value;
      });
    });
  }

  @override
  void dispose() {
    WindowManager.instance.removeListener(this);
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
                  Bundle data = Bundle();
                  data.putString('executable', detail.files[0].path);
                  data.putInt('duration', 0);
                  _showDialogSaveForm(
                      title: "Add game",
                      initialValue: GameObject.build(data.flatten()));
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
              child: GalleryPage(
                adapter: GameGalleryAdapter(
                  list: _listItem,
                ),
                controller: _gpController,
              ),
            ),
            floatingActionButton: ExpandableFab(distance: 112.0, children: [
              ActionButton(
                onPressed: () => _showDialogSaveForm(title: "Add game"),
                icon: const Icon(Icons.add),
              ),
              ActionButton(
                onPressed: () {
                  if (_listItem.isEmpty) {
                    showErrno(context, Errno.listEmpty);
                  } else {
                    GameObject item = _getItem(_gpController.highlightPosition);
                    _showDialogSaveForm(title: "Edit game", initialValue: item);
                  }
                },
                icon: const Icon(Icons.edit),
              ),
              ActionButton(
                onPressed: _showDialogRemoveItem,
                icon: const Icon(Icons.remove),
              ),
              ActionButton(
                onPressed: () =>
                    _startGame(_getItem(_gpController.highlightPosition)),
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
