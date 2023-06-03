import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangw/interface/cloneable.dart';
import 'package:path/path.dart';

class PlayTime {
  int _playHours = 0;
  int _playMinutes = 0;
  int _playSeconds = 0;
  int _duration = 0;

  int get hours => _playHours;
  int get minutes => _playMinutes;
  int get seconds => _playSeconds;

  PlayTime._internal(duration) {
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

class GameCard implements Cloneable {
  final String title;
  final String executable;
  final String artwork;
  final String bigPicture;
  final String banner;
  final String logo;
  late final PlayTime playTime;
  final int id;

  GameCard(this.title, this.executable, this.artwork, this.bigPicture,
      this.banner, this.logo, int duration,
      {this.id = 0}) {
    playTime = PlayTime._internal(duration);
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

  factory GameCard.build(Map<String, Object?> data) => GameCard(
      (data['title'] ?? '') as String,
      (data['executable'] ?? '') as String,
      (data['artwork'] ?? '') as String,
      (data['bigPicture'] ?? '') as String,
      (data['banner'] ?? '') as String,
      (data['logo'] ?? '') as String,
      (data['duration'] ?? 0) as int,
      id: (data['id'] ?? 0) as int);

  @override
  GameCard clone({Map<String, Object> withChanges = const {}}) {
    withChanges['title'] = withChanges['title'] ?? title;
    withChanges['executable'] = withChanges['executable'] ?? executable;
    withChanges['artwork'] = withChanges['artwork'] ?? artwork;
    withChanges['bigPicture'] = withChanges['bigPicture'] ?? bigPicture;
    withChanges['banner'] = withChanges['banner'] ?? banner;
    withChanges['logo'] = withChanges['logo'] ?? logo;
    withChanges['duration'] = withChanges['duration'] ?? playTime.getDuration();
    withChanges['id'] = withChanges['id'] ?? id;

    return GameCard.build(withChanges);
  }
}
