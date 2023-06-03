import 'package:flutter/material.dart';

class Errno {
  Errno({required this.id, required this.message});

  final String id;
  final String message;

  static final Errno dragAndDropMultipleItems =
      Errno(id: 'E001', message: "Only supports 1 file at the moment!");
  static final Errno fileNotSelected =
      Errno(id: 'E002', message: "No file selected!");
  static final Errno imageNotFound =
      Errno(id: 'E003', message: "No image found!");
  static final Errno listEmpty =
      Errno(id: 'E004', message: "No item in the list!");
}

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
