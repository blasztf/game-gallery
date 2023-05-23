import 'dart:convert';
import 'dart:io' show Directory, File, FileMode, FileSystemEntity, HttpClient;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

// context
class ImageFinder {
  ImageFinder.use(this.provider);

  final ImageProvider provider;

  Future<ImageList> find(String title) => provider.findImage(title);
}

// interface
abstract class ImageProvider {
  Future<ImageList> findImage(String title);

  final String dir = join(Directory.current.path, '.cache');

  String getCacheResponse(String url) {
    String result = "";

    String cacheId = md5.convert(utf8.encode(url)).toString();

    Directory cacheDir;
    if (!((cacheDir = Directory(dir)).existsSync())) {
      cacheDir.createSync(recursive: true);
    }

    String filename;
    DateTimeRange dtr;
    for (FileSystemEntity file in cacheDir.listSync()) {
      // cache exists
      if ((filename = basename(file.path)).startsWith("${cacheId}_")) {
        filename = filename.split('_')[1].replaceAll(extension(filename), '');
        dtr = DateTimeRange(
            start: DateTime.fromMillisecondsSinceEpoch(filename as int),
            end: DateTime.now());

        // cache valid
        if (dtr.duration.inMinutes < 30) {
          result = File(file.path).readAsStringSync();
        }

        break;
      }
    }

    return result;
  }

  bool putCacheResponse(String url, String contents) {
    bool result = false;

    String cacheId = md5.convert(utf8.encode(url)).toString();

    Directory cacheDir;
    if (!((cacheDir = Directory(dir)).existsSync())) {
      cacheDir.createSync(recursive: true);
    }

    try {
      File(join(cacheDir.path,
              "${cacheId}_${DateTime.now().millisecondsSinceEpoch}.cache"))
          .writeAsStringSync(contents, flush: true);
      result = true;
    } catch (e) {
      //
    }

    return result;
  }

  Future<String> getResponse(String url) async {
    String result = "";

    result = getCacheResponse(url);

    if (result.isEmpty) {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        result = response.body;
        putCacheResponse(url, result);
      }
    }

    return result;
  }
}

class SteamPoweredImageProvider extends ImageProvider {
  @override
  Future<ImageList> findImage(String title) {
    // TODO: implement findImage
    throw UnimplementedError();
  }
}

class SteamGridDBImageProvider extends ImageProvider {
  @override
  Future<ImageList> findImage(String title) async {
    String gameId = await getGameId(title);
    return await getGameImages(gameId);
  }

  Future<ImageList> getGameImages(String gameId) async {
    ImageList listImage = ImageList.empty;

    String response = await getResponse(
        "https://www.steamgriddb.com/api/public/game/$gameId/home");
    var result = json.decode(response);

    if (result['success']) {
      listImage = ImageList();
      listImage.artworks.addAll([
        for (var item in result['data']['grids'])
          if (item['width'] == 600 && item['height'] == 900)
            item['url'] as String
      ]);
      listImage.banners.addAll(
          [for (var item in result['data']['heroes']) item['url'] as String]);
      listImage.bigPictures.addAll([
        for (var item in result['data']['grids'])
          if (item['width'] == 920 && item['height'] == 430)
            item['url'] as String
      ]);
      listImage.logos.addAll(
          [for (var item in result['data']['logos']) item['url'] as String]);
    }

    return listImage;
  }

  Future<String> getGameId(String title) async {
    String gameId = "";

    String response = await getResponse(
        "https://www.steamgriddb.com/api/public/search/autocomplete?term=$title");
    var result = json.decode(response);

    if (result['success']) {
      for (var item in result['data']) {
        if (item['name'] == title) {
          gameId = item['id'];
          break;
        }
      }
    }

    return gameId;
  }
}

// class ImageObject {
//   ImageObject(this.artwork, this.banner, this.bigPicture, this.logo);

//   final String artwork;
//   final String banner;
//   final String bigPicture;
//   final String logo;
// }

class ImageList {
  ImageList();

  static final ImageList empty = ImageList();

  final List<String> artworks = [];
  final List<String> banners = [];
  final List<String> bigPictures = [];
  final List<String> logos = [];
}

////////

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

  // String _get(String path, String type) {
  //   String hashFilename =
  //       md5.convert(utf8.encode(path)).toString() + extension(path);
  //   return join(dir, type, hashFilename);
  // }

  String _get(String imageId, String type) {
    return join(dir, type, imageId);
  }

  Future<String> _put(String path, String type) async {
    path = path.replaceAll(RegExp(r'(\?|\#).*'), '');
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

class FileSaver {
  FileSaver(String path) {
    _path = path;
  }

  late final String _path;

  Future<bool> saveTo(String dstPath, {String as = ''}) async {
    return await (_isFileFromInternet(_path)
        ? _downloadFile(_path, dstPath, as)
        : _copyFile(_path, dstPath, as));
  }

  Future<bool> _downloadFile(String path, String dstPath, String as) async {
    bool result = true;
    var url = Uri.parse(path);
    var httpClient = HttpClient();
    var httpRequest = await httpClient.getUrl(url);
    var httpResponse = await httpRequest.close();
    var filename = as.isEmpty ? basename(path) : as;
    filename = filename.replaceAll(RegExp(r'(\?|\#).*'), '');
    var file = File(join(dstPath, filename));
    try {
      await httpResponse.forEach((bytes) {
        file.writeAsBytesSync(bytes, mode: FileMode.append);
      });
    } catch (err) {
      result = false;
    } finally {
      httpClient.close();
    }

    return result;
  }

  Future<bool> _copyFile(String path, String dstPath, String as) async {
    bool result = true;
    File file = File(path);
    String filename = as.isEmpty ? basename(path) : as;
    try {
      file.copy(join(dstPath, filename));
    } catch (err) {
      result = false;
    }
    return result;
  }

  // Check if file from local or internet
  bool _isFileFromInternet(String path) {
    return path.startsWith(RegExp(r'https?://'));
  }
}
