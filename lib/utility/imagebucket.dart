import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mangw/utility/filesaver.dart';
import 'package:path/path.dart';

class ImageBucket {
  static ImageBucket get instance => _instance;
  static final ImageBucket _instance = ImageBucket._internal();

  final String dir = join(Directory.current.path, 'images');

  ImageBucket._internal() {
    prepareBucket();
  }

  void prepareBucket() {
    Directory(join(dir, 'artwork')).createSync(recursive: true);
    Directory(join(dir, 'banner')).createSync(recursive: true);
    Directory(join(dir, 'big_picture')).createSync(recursive: true);
    Directory(join(dir, 'logo')).createSync(recursive: true);
  }

  String _get(String imageId, String type) {
    return join(dir, type, imageId);
  }

  Future<String> _put(String path, String type) async {
    path = path.replaceAll(RegExp(r'(\?|\#).*'), '');

    // Determine if path is path or filename-only.
    if (!path.contains('/')) {
      if (_exists(path, type)) {
        return path;
      }
    }

    String hashFilename = md5
            .convert(
                utf8.encode("$path${DateTime.now().millisecondsSinceEpoch}"))
            .toString() +
        extension(path);
    if (await FileSaver(path).saveTo(join(dir, type), as: hashFilename)) {
      return hashFilename;
    } else {
      return "";
    }
  }

  bool _exists(String filename, String type) {
    return File(join(dir, type, filename)).existsSync();
  }

  String getArtwork(String path) {
    return _get(path, 'artwork');
  }

  String getBanner(String path) {
    return _get(path, 'banner');
  }

  String getBigPicture(String path) {
    return _get(path, 'big_picture');
  }

  String getLogo(String path) {
    return _get(path, 'logo');
  }

  Future<String> putArtwork(String path) async {
    return await _put(path, 'artwork');
  }

  Future<String> putBanner(String path) async {
    return await _put(path, 'banner');
  }

  Future<String> putBigPicture(String path) async {
    return await _put(path, 'big_picture');
  }

  Future<String> putLogo(String path) async {
    return await _put(path, 'logo');
  }
}
