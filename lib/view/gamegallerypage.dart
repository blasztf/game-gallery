import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:mangw/complement/am.dart';
import 'package:mangw/error/errno.dart';
import 'package:mangw/model/gamecard.dart';
import 'package:mangw/model/gamecardrepo.dart';
import 'package:mangw/utility/imagebucket.dart';
import 'package:mangw/view/expandablefab.dart';
import 'package:mangw/view/gallerypage.dart';
import 'package:mangw/view/gamegalleryoverlay.dart';
import 'package:mangw/view/savegameform.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

class GameGalleryAdapter extends GalleryPageAdapter<GameCard> {
  GameGalleryAdapter._(this._list, this._onTap);

  factory GameGalleryAdapter(
          {required List<GameCard> list, Function(GameCard)? onItemTap}) =>
      GameGalleryAdapter._(list, onItemTap);

  final List<GameCard> _list;
  final Function(GameCard)? _onTap;

  @override
  GameCard getItem(int index) {
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
  void onItemTap(GameCard item) {
    _onTap?.call(item);
  }
}

class GameGalleryPage extends StatefulWidget {
  const GameGalleryPage({super.key, required this.repository});

  final GameCardRepository repository;

  @override
  State<GameGalleryPage> createState() => _GameGalleryPageState();
}

class _GameGalleryPageState extends State<GameGalleryPage>
    with WidgetsBindingObserver, WindowListener, AlertMessage {
  List<GameCard> _listItem = [];

  bool _isActive = true;

  int _overlayState = 0;
  final int _overlayEnabled = 1;
  final int _overlayGameRunning = 2;
  final int _overlayFilePickerOpening = 4;
  final int _overlayFileDragging = 8;

  final Controller _gamepadController = Controller(index: 0);
  final GalleryPageController _gpController = GalleryPageController();

  int get _sizeItem => _listItem.length;
  String _nowPlayingLabel = "Game is running...";

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

  Future<void> _saveItem(final GameCard item, final GameCard? oldItem) async {
    setState(() {
      _overlayState = _overlayEnabled;
      _isActive = false;
    });

    var artwork = await ImageBucket.instance.putArtwork(item.artwork);
    var banner = await ImageBucket.instance.putBanner(item.banner);
    var bigPicture = await ImageBucket.instance.putBigPicture(item.bigPicture);
    var logo = await ImageBucket.instance.putLogo(item.logo);

    var newItem = GameCard(item.title, item.executable, artwork, bigPicture,
        banner, logo, item.playTime.getDuration(),
        id: item.id);

    await widget.repository.save([newItem]);

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

  Future<void> _removeItem(final GameCard item) async {
    setState(() {
      _overlayState = _overlayEnabled;
      _isActive = false;
    });

    await widget.repository.delete([item]);
    _listItem.remove(item);

    setState(() {
      _overlayState = 0;
      _isActive = true;
    });

    // _gpController.highlightItem(_gpController.highlightPosition > 0
    //     ? _gpController.highlightPosition - 1
    //     : 0);
  }

  GameCard _getItem(int index) {
    return _listItem[index];
  }

  void _startGame(GameCard game) {
    setState(() {
      _nowPlayingLabel = "Now playing ${game.title}...";
      _overlayState = _overlayEnabled | _overlayGameRunning;
      _isActive = false;
    });

    game.play(callback: (gamePid) {
      widget.repository.save([game]).then((affectedRows) {
        if (affectedRows > 0) {
          showAlertMessage(
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
            onPressed: () async {
              if (context.mounted) Navigator.pop(context);
              await _removeItem(_getItem(_gpController.highlightPosition));
            },
            child: const Text("Yes"),
          )
        ],
      ),
    );
  }

  void _showDialogSaveForm({required String title, GameCard? initialValue}) {
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
              child: SaveGameForm(
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

    widget.repository.loadAll().then((value) {
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
                  _showDialogSaveForm(
                      title: "Add game",
                      initialValue: GameCard.build(
                          {'executable': detail.files[0].path, 'duration': 0}));
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
                    GameCard item = _getItem(_gpController.highlightPosition);
                    _showDialogSaveForm(title: "Edit game", initialValue: item);
                  }
                },
                icon: const Icon(Icons.edit_note),
              ),
              ActionButton(
                onPressed: _showDialogRemoveItem,
                icon: const Icon(Icons.remove),
              ),
              ActionButton(
                onPressed: () {
                  _startGame(_getItem(_gpController.highlightPosition));
                },
                icon: const Icon(Icons.play_arrow),
              ),
            ]),
          ),
          if (_overlayState & _overlayEnabled != 0)
            GameGalleryOverlay(
              message: _overlayState & _overlayFileDragging != 0
                  ? "Drag and drop file to add new item"
                  : _overlayState & _overlayFilePickerOpening != 0
                      ? "Pick a file..."
                      : _overlayState & _overlayGameRunning != 0
                          ? _nowPlayingLabel
                          : "",
            )
        ],
      ),
    );
  }
}
