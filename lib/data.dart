import 'dart:collection';

import 'dart:io' show Directory, Process, ProcessResult;

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Bundle {
  final Map<String, Object> _bundle = HashMap();

  int getInt(String key) {
    return (_bundle[key] ?? -1) as int;
  }

  String getString(String key) {
    return (_bundle[key] ?? '') as String;
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
    ProcessResult p = await Process.run(executable, [],
        workingDirectory: dirname(executable));
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
      (data['title'] ?? '') as String,
      (data['executable'] ?? '') as String,
      (data['artwork'] ?? '') as String,
      (data['bigPicture'] ?? '') as String,
      (data['banner'] ?? '') as String,
      (data['logo'] ?? '') as String,
      (data['duration'] ?? 0) as int,
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
