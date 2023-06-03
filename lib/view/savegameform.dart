import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mangw/error/errno.dart';
import 'package:mangw/model/formdata.dart';
import 'package:mangw/model/gamecard.dart';
import 'package:mangw/utility/imagefinder.dart';
import 'package:mangw/utility/imageprovider.dart';
import 'package:mangw/utility/steamgriddbprovider.dart';
import 'package:mangw/utility/steampoweredprovider.dart';
import 'package:mangw/view/gameform.dart';
import 'package:mangw/view/imagechooser.dart';

class SaveGameForm extends StatefulWidget {
  const SaveGameForm(
      {super.key,
      required this.onSubmit,
      this.initialValue,
      required this.onCancel});

  final void Function(GameCard) onSubmit;
  final GameCard? initialValue;
  final void Function() onCancel;

  @override
  State<StatefulWidget> createState() => _SaveGameFormState();
}

class _SaveGameFormState extends State<SaveGameForm> {
  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _artworkTextController = TextEditingController();
  final TextEditingController _bigPictureTextController =
      TextEditingController();
  final TextEditingController _bannerTextController = TextEditingController();
  final TextEditingController _logoTextController = TextEditingController();

  final TextEditingController _executableTextController =
      TextEditingController();

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
      ImageBundle list, FormData data, String key) async {
    List<String> images;
    String nextKey;

    if (key == 'Artwork') {
      images = list.artworks;
      nextKey = 'Banner';
    } else if (key == 'Banner') {
      images = list.banners;
      nextKey = 'Big Picture';
    } else if (key == 'Big Picture') {
      images = list.bigPictures;
      nextKey = 'Logo';
    } else if (key == 'Logo') {
      images = list.logos;
      nextKey = '';
    } else {
      return;
    }

    await showDialog(
        context: context,
        builder: (contextBuilder) {
          return ImageChooserDialog(
              title: key,
              listImage: images,
              onChosen: (image) {
                Navigator.pop(context);
                data.putString(key, image);
              });
        });

    await _recursiveShowImageChooserDialog(list, data, nextKey);
  }

  Future<void> _showImageChooserDialog(ImageBundle list) async {
    FormData data = FormData();

    await _recursiveShowImageChooserDialog(list, data, 'Artwork');

    _artworkTextController.text = data.getString('Artwork');
    _bannerTextController.text = data.getString('Banner');
    _bigPictureTextController.text = data.getString('Big Picture');
    _logoTextController.text = data.getString('Logo');
  }

  @override
  void initState() {
    super.initState();
    _executableTextController.text = widget.initialValue?.executable ?? '';

    _titleTextController.text = widget.initialValue?.title ?? '';
    _artworkTextController.text = widget.initialValue?.artwork ?? '';
    _bannerTextController.text = widget.initialValue?.banner ?? '';
    _bigPictureTextController.text = widget.initialValue?.bigPicture ?? '';
    _logoTextController.text = widget.initialValue?.logo ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isFilePickerOpened,
      child: GameForm(
        submitLabel: const Text("Save"),
        onCancel: widget.onCancel,
        onSubmit: (formData) {
          formData.putInt('duration', 0);
          widget.onSubmit(GameCard.build(formData.flatten()));
          return true;
        },
        children: (formData) {
          formData.putInt('id', widget.initialValue?.id ?? -1);
          return [
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
                    ImageBundle bundle = await ImageFinder.use([
                      SteamPoweredImageProvider(),
                      SteamGridDBImageProvider(),
                    ]).find(_titleTextController.text);

                    if (bundle != ImageBundle.empty) {
                      await _showImageChooserDialog(bundle);
                    } else {
                      if (context.mounted) {
                        showErrno(context, Errno.imageNotFound);
                      }
                    }
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
          ];
        },
      ),
    );
  }
}
