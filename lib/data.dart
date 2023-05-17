import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Config {
  static final String dataJsonPath =
      "Game_Gallery${Platform.pathSeparator}data.json";
}

class GameGalleryStorage {
  const GameGalleryStorage();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    final dataJsonPath = Config.dataJsonPath;
    return File('$path${Platform.pathSeparator}$dataJsonPath');
  }

  Future<List<GameGalleryData>> load() async {
    try {
      final File file = await _localFile;
      final contents = await file.readAsString();
      final parsed = jsonDecode(contents).cast<Map<String, dynamic>>();
      return parsed
          .map<GameGalleryData>((json) => GameGalleryData.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> save(List<GameGalleryData> data) async {
    try {
      final file = await _localFile;
      final parsed = data.map((item) => GameGalleryData.toJson(item)).toList();
      final String contents = jsonEncode(parsed);

      file.writeAsString(contents);
      return true;
    } catch (e) {
      // If encountering an error, return 0
      return false;
    }
  }
}

class GameGalleryData {
  final String executablePath;
  final String coverPath;

  static final GameGalleryData invalid =
      GameGalleryData(executablePath: '', coverPath: '');

  static bool isValid(GameGalleryData data) => data == GameGalleryData.invalid;

  GameGalleryData({required this.executablePath, required this.coverPath});

  factory GameGalleryData.fromJson(Map<String, dynamic> json) {
    return GameGalleryData(
        executablePath: json['executablePath'] as String,
        coverPath: json['coverPath'] as String);
  }

  static Map<String, dynamic> toJson(GameGalleryData value) {
    return {
      'executablePath': value.executablePath,
      'coverPath': value.coverPath
    };
  }

  void start(Function(int) callback) async {
    ProcessResult p = await Process.run(executablePath, []);
    callback(p.pid);
  }
}
