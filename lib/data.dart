import 'dart:collection';
import 'dart:convert';
import 'dart:io'
    show Directory, File, FileMode, HttpClient, Process, ProcessResult;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Bundle {
  final Map<String, Object> _bundle = HashMap();

  int getInt(String key) {
    return _bundle[key] as int;
  }

  String getString(String key) {
    return _bundle[key] as String;
  }

  void putInt(String key, int value) {
    _bundle[key] = value;
  }

  void putString(String key, String value) {
    _bundle[key] = value;
  }

  Map<String, Object> flatten() {
    return HashMap.from(_bundle);
  }
}

class PlayTime {
  int _playHours = 0;
  int _playMinutes = 0;
  int _playSeconds = 0;
  int _duration = 0;

  int get hours => _playHours;
  int get minutes => _playMinutes;
  int get seconds => _playSeconds;

  PlayTime(duration) {
    addDuration(duration);
  }

  void addDuration(int duration) {
    _duration += duration;
    _parse();
  }

  int getDuration() {
    return _duration;
  }

  void _parse() {
    _playHours = _duration ~/ 3600;
    _playMinutes = (_duration - _playHours * 3600) ~/ 60;
    _playSeconds = _duration - (_playHours * 3600) - (_playMinutes * 60);
  }
}

class GameObject {
  final String title;
  final String executable;
  final String artwork;
  final String bigPicture;
  final String banner;
  final String logo;
  late final PlayTime playTime;
  final int id;

  GameObject(this.title, this.executable, this.artwork, this.bigPicture,
      this.banner, this.logo, int duration,
      {this.id = 0}) {
    playTime = PlayTime(duration);
  }

  void play({Function(int)? callback}) async {
    var startTime = DateTime.now();
    ProcessResult p = await Process.run(executable, []);
    var playDuration =
        DateTimeRange(start: startTime, end: DateTime.now()).duration.inSeconds;
    playTime.addDuration(playDuration);
    callback?.call(p.pid);
  }

  Map<String, dynamic> transform() {
    return {
      if (id > 0) 'id': id,
      'title': title,
      'executable': executable,
      'artwork': artwork,
      'bigPicture': bigPicture,
      'banner': banner,
      'logo': logo,
      'duration': playTime.getDuration()
    };
  }

  factory GameObject.build(Map<String, Object?> data) => GameObject(
      data['title'] as String,
      data['executable'] as String,
      data['artwork'] as String,
      data['bigPicture'] as String,
      data['banner'] as String,
      data['logo'] as String,
      data['duration'] as int,
      id: (data['id'] ?? 0) as int);
}

class GameObjectDatabase {
  const GameObjectDatabase(this.dbFactory);

  final DatabaseFactory dbFactory;
  final String table = "Game";
  final String dbGame = "game.db";

  Future<Database> openDatabase() async {
    return await dbFactory.openDatabase(join(Directory.current.path, dbGame),
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) {
            db.execute('''
                  CREATE TABLE $table (
                    id INTEGER PRIMARY KEY,
                    title TEXT,
                    executable TEXT,
                    artwork TEXT,
                    bigPicture TEXT,
                    banner TEXT,
                    logo TEXT,
                    duration INTEGER
                  )
                  ''');
          },
        ));
  }

  Future<int> delete(List<GameObject> goCollection) async {
    int result = 0;
    Database db = await openDatabase();
    for (GameObject go in goCollection) {
      if (await db.delete(table, where: 'id = ?', whereArgs: [go.id]) != 0) {
        result++;
      }
    }
    db.close();
    return result;
  }

  Future<int> save(List<GameObject> goCollection) async {
    int result = 0;
    Database db = await openDatabase();
    for (GameObject go in goCollection) {
      if (await db.insert(table, go.transform(),
              conflictAlgorithm: ConflictAlgorithm.replace) !=
          0) {
        result++;
      }
    }
    db.close();
    return result;
  }

  Future<List<GameObject>> load() async {
    List<GameObject> result;
    Database db = await openDatabase();
    result = (await db.query(table))
        .map<GameObject>((data) => GameObject.build(data))
        .toList();
    db.close();
    return result;
  }
}

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
