import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:game_gallery/data.dart';
import 'package:game_gallery/img.dart';
import 'package:game_gallery/item.dart';
import 'package:game_gallery/style.dart';

class GameForm extends StatelessWidget {
  const GameForm({
    super.key,
    this.onSubmit,
    this.onCancel,
    this.onCreateFields,
    this.submitButtonLabel = const Text("Submit"),
  });

  final bool Function(Bundle)? onSubmit;
  final void Function()? onCancel;
  final List<Widget> Function(Bundle)? onCreateFields;
  final Text submitButtonLabel;

  @override
  Widget build(BuildContext context) {
    const double padding = 8.0;
    Bundle formData = Bundle();
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return Theme(
      data: Theme.of(context),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...onCreateFields?.call(formData).map(
                        (field) => Padding(
                          padding: const EdgeInsets.all(padding),
                          child: field,
                        ),
                      ) ??
                  [],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(padding),
                      child: ElevatedButton(
                        onPressed: onCancel,
                        child: const Text("Cancel"),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(padding),
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            if (onSubmit?.call(formData) ?? false) {
                              formData = Bundle();
                            }
                          }
                        },
                        child: submitButtonLabel,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class GameAddForm extends StatefulWidget {
  const GameAddForm(
      {super.key,
      required this.onSubmit,
      this.initialValue,
      required this.onCancel});

  final void Function(Bundle) onSubmit;
  final Bundle? initialValue;
  final void Function() onCancel;

  @override
  State<StatefulWidget> createState() => _GameAddFormState();
}

class _GameAddFormState extends State<GameAddForm> {
  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _artworkTextController = TextEditingController();
  final TextEditingController _bigPictureTextController =
      TextEditingController();
  final TextEditingController _bannerTextController = TextEditingController();
  final TextEditingController _logoTextController = TextEditingController();

  late final TextEditingController _executableTextController;

  bool _isFilePickerOpened = false;

  Future<PlatformFile?> pickGameFile() async {
    if (_isFilePickerOpened) return null;

    setState(() {
      _isFilePickerOpened = true;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: "Select game executable",
        type: FileType.custom,
        allowedExtensions: ['exe']);

    setState(() {
      _isFilePickerOpened = false;
    });

    return result?.files.single;
  }

  Future<PlatformFile?> pickImageFile() async {
    if (_isFilePickerOpened) return null;

    setState(() {
      _isFilePickerOpened = true;
    });

    FilePickerResult? result = await FilePicker.platform
        .pickFiles(dialogTitle: "Select image file", type: FileType.image);

    setState(() {
      _isFilePickerOpened = false;
    });

    return result?.files.single;
  }

  void _showImageChooserDialog(ImageList list) {
    showDialog(
        context: context,
        builder: (contextBuilder) {
          return ImageChooserDialog(
              listImage: list,
              onChosen: (bundle) {
                Navigator.pop(context);
                _artworkTextController.text = bundle.getString('artwork');
                _bannerTextController.text = bundle.getString('banner');
                _bigPictureTextController.text =
                    bundle.getString('big_picture');
                _logoTextController.text = bundle.getString('logo');
              });
        });
  }

  @override
  void initState() {
    super.initState();
    _executableTextController = TextEditingController(
        text: widget.initialValue?.getString('executable'));
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isFilePickerOpened,
      child: GameForm(
        submitButtonLabel: const Text("Add"),
        onCancel: widget.onCancel,
        onSubmit: (formData) {
          formData.putInt('duration', 0);
          widget.onSubmit(formData);
          return true;
        },
        onCreateFields: (formData) => [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _titleTextController,
                  decoration: const InputDecoration(
                    labelText: "Game Title text",
                    hintText: "Input game title",
                  ),
                  onSaved: (newValue) {
                    formData.putString('title', newValue!);
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? false) {
                      return "Text cannot be empty!";
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                onPressed: () async {
                  ImageList list =
                      await ImageFinder.use(SteamGridDBImageProvider())
                          .find(_titleTextController.text);
                  _showImageChooserDialog(list);
                },
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          TextFormField(
            controller: _executableTextController,
            decoration: const InputDecoration(
              labelText: "Game Executable path",
              hintText: "Click to select file",
            ),
            onTap: () async {
              PlatformFile? file = await pickGameFile();
              _executableTextController.text = file?.path ?? '';
            },
            onSaved: (newValue) {
              formData.putString('executable', newValue!);
            },
            validator: (value) {
              if (value?.isEmpty ?? false) {
                return "Path cannot be empty!";
              }
              return null;
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _artworkTextController,
                  decoration: const InputDecoration(
                    labelText: "Game Artwork path",
                    hintText: "Click search icon to select file",
                  ),
                  onSaved: (newValue) {
                    formData.putString('artwork', newValue!);
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? false) {
                      return "Path cannot be empty!";
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                onPressed: () async {
                  PlatformFile? file = await pickImageFile();
                  _artworkTextController.text = file?.path ?? '';
                },
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bigPictureTextController,
                  decoration: const InputDecoration(
                    labelText: "Game Big Picture path",
                    hintText: "Click search icon to select file",
                  ),
                  onSaved: (newValue) {
                    formData.putString('bigPicture', newValue!);
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? false) {
                      return "Path cannot be empty!";
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                onPressed: () async {
                  PlatformFile? file = await pickImageFile();
                  _bigPictureTextController.text = file?.path ?? '';
                },
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bannerTextController,
                  decoration: const InputDecoration(
                    labelText: "Game Banner path",
                    hintText: "Click search icon to select file",
                  ),
                  onSaved: (newValue) {
                    formData.putString('banner', newValue!);
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? false) {
                      return "Path cannot be empty!";
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                onPressed: () async {
                  PlatformFile? file = await pickImageFile();
                  _bannerTextController.text = file?.path ?? '';
                },
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _logoTextController,
                  decoration: const InputDecoration(
                    labelText: "Game Logo path",
                    hintText: "Click search icon to select file",
                  ),
                  onSaved: (newValue) {
                    formData.putString('logo', newValue!);
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? false) {
                      return "Path cannot be empty!";
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                onPressed: () async {
                  PlatformFile? file = await pickImageFile();
                  _logoTextController.text = file?.path ?? '';
                },
                icon: const Icon(Icons.search),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class ImageChooserDialog extends StatefulWidget {
  const ImageChooserDialog(
      {super.key, required this.listImage, required this.onChosen});

  final ImageList listImage;
  final Function(Bundle) onChosen;

  @override
  State<StatefulWidget> createState() => _ImageChooserDialogState();
}

class _ImageChooserDialogState extends State<ImageChooserDialog> {
  List<String> _listItem = [];

  final double _spacing = 25.0;

  int get _sizeItem => _listItem.length;

  final ScrollController _scrollController = ScrollController();

  final int _stateArtwork = 1;
  final int _stateBanner = 2;
  final int _stateBigPicture = 4;
  final int _stateLogo = 8;

  int _state = 1;

  final Bundle _bundle = Bundle();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _stateArtwork) {
      _listItem = widget.listImage.artworks;
    } else if (_state == _stateBanner) {
      _listItem = widget.listImage.banners;
    } else if (_state == _stateBigPicture) {
      _listItem = widget.listImage.bigPictures;
    } else if (_state == _stateLogo) {
      _listItem = widget.listImage.logos;
    }
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_spacing),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        color: mcgpalette0Accent,
        child: AlignedGridView.count(
          controller: _scrollController,
          padding: EdgeInsets.all(_spacing),
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          crossAxisCount: 4,
          itemCount: _sizeItem,
          itemBuilder: (BuildContext context, int index) => ImageChooserItem(
            data: _listItem[index],
            isSelected: false,
            onPress: (data) {
              if (_state == _stateArtwork) {
                _bundle.putString('artwork', _listItem[index]);
                setState(() {
                  _state = _stateBanner;
                });
              } else if (_state == _stateBanner) {
                _bundle.putString('banner', _listItem[index]);
                setState(() {
                  _state = _stateBigPicture;
                });
              } else if (_state == _stateBigPicture) {
                _bundle.putString('big_picture', _listItem[index]);
                setState(() {
                  _state = _stateLogo;
                });
              } else if (_state == _stateLogo) {
                _bundle.putString('logo', _listItem[index]);
                _state = 0;
                widget.onChosen(_bundle);
              }
            },
          ),
        ),
      ),
    );
  }
}
