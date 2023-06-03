import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class ImageBundle {
  ImageBundle._internal() {
    artworks = [];
    banners = [];
    bigPictures = [];
    logos = [];
  }

  ImageBundle._zeroes() {
    artworks = List.unmodifiable([]);
    banners = List.unmodifiable([]);
    bigPictures = List.unmodifiable([]);
    logos = List.unmodifiable([]);
  }

  static final ImageBundle empty = ImageBundle._zeroes();

  late final List<String> artworks;
  late final List<String> banners;
  late final List<String> bigPictures;
  late final List<String> logos;

  ImageBundle combine(ImageBundle imageBundle) {
    artworks.addAll(imageBundle.artworks);
    banners.addAll(imageBundle.banners);
    bigPictures.addAll(imageBundle.bigPictures);
    logos.addAll(imageBundle.logos);
    return this;
  }
}

abstract class ImageProvider {
  Future<ImageBundle> findImages(String title);

  final String dir = join(Directory.current.path, '.cache');

  ImageBundle createImageBundle() {
    return ImageBundle._internal();
  }

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
            start: DateTime.fromMillisecondsSinceEpoch(int.parse(filename)),
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

  Future<String> getResponse(String url, {Map<String, String>? headers}) async {
    String result = "";

    result = getCacheResponse(url);

    if (result.isEmpty) {
      http.Response response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        result = response.body;
        putCacheResponse(url, result);
      }
    }

    return result;
  }

  Future<String> postResponse(String url,
      {Map<String, String>? headers, Object? body}) async {
    String result = "";

    result = getCacheResponse(url);

    if (result.isEmpty) {
      http.Response response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        result = response.body;
        putCacheResponse(url, result);
      }
    }

    return result;
  }
}
