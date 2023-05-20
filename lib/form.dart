import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:game_gallery/data.dart';

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
          TextFormField(
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
