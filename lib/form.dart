import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:game_gallery/data.dart';
import 'package:game_gallery/img.dart';
import 'package:game_gallery/item.dart';
import 'package:game_gallery/page.dart';
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

  Future<void> _recursiveShowImageChooserDialog(
      ImageList list, Bundle data, String key) async {
    List<String> images;
    String nextKey;

    if (key == 'artwork') {
      images = list.artworks;
      nextKey = 'banner';
    } else if (key == 'banner') {
      images = list.banners;
      nextKey = 'big_picture';
    } else if (key == 'big_picture') {
      images = list.bigPictures;
      nextKey = 'logo';
    } else if (key == 'logo') {
      images = list.logos;
      nextKey = '';
    } else {
      return;
    }

    await showDialog(
        context: context,
        builder: (contextBuilder) {
          return ImageChooserDialog(
              listImage: images,
              onChosen: (image) {
                Navigator.pop(context);
                data.putString(key, image);
              });
        });

    await _recursiveShowImageChooserDialog(list, data, nextKey);
  }

  Future<void> _showImageChooserDialog(ImageList list) async {
    Bundle data = Bundle();

    await _recursiveShowImageChooserDialog(list, data, 'artwork');

    _artworkTextController.text = data.getString('artwork');
    _bannerTextController.text = data.getString('banner');
    _bigPictureTextController.text = data.getString('big_picture');
    _logoTextController.text = data.getString('logo');
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
                  await _showImageChooserDialog(list);
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

class ImageChooserAdapter extends GalleryPageAdapter<String> {
  ImageChooserAdapter._(this._list, this._onTap);

  factory ImageChooserAdapter(
          {required List<String> list, Function(String)? onItemTap}) =>
      ImageChooserAdapter._(list, onItemTap);

  final List<String> _list;
  final Function(String)? _onTap;

  @override
  String getItem(int index) {
    return _list[index];
  }

  @override
  String getItemImage(int index) {
    return _list[index];
  }

  @override
  int getSize() {
    return _list.length;
  }

  @override
  void onItemTap(String item) {
    _onTap?.call(item);
  }
}

class ImageChooserDialog extends StatefulWidget {
  const ImageChooserDialog(
      {super.key, required this.listImage, required this.onChosen});

  final List<String> listImage;
  final Function(String) onChosen;

  @override
  State<StatefulWidget> createState() => _ImageChooserDialogState();
}

class _ImageChooserDialogState extends State<ImageChooserDialog> {
  final double _spacing = 25.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_spacing),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: GalleryPage(
          adapter: ImageChooserAdapter(
            list: widget.listImage,
            onItemTap: (data) {
              widget.onChosen(data);
            },
          ),
        ));
  }
}
