import 'dart:io';

import 'package:mangw/interface/repository.dart';
import 'package:mangw/model/gamecard.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class GameCardRepository implements Repository<GameCard> {
  const GameCardRepository(this.dbFactory);

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

  @override
  Future<int> delete(List<GameCard> cards) async {
    int result;

    if (cards.isEmpty) return 0;

    String whereClause = (" OR id = ?" * cards.length).substring(4);
    List<int> ids = cards.map<int>((card) => card.id).toList();

    Database db = await openDatabase();
    result = await db.delete(table, where: whereClause, whereArgs: ids);

    db.close();
    return result;
  }

  @override
  Future<List<GameCard>> load(List<int> ids) async {
    List<GameCard> result;

    if (ids.isEmpty) return [];

    String whereClause = (" OR id = ?" * ids.length).substring(4);

    Database db = await openDatabase();
    result = (await db.query(table, where: whereClause, whereArgs: ids))
        .map<GameCard>((data) => GameCard.build(data))
        .toList();
    db.close();
    return result;
  }

  @override
  Future<List<GameCard>> loadAll() async {
    List<GameCard> result;
    Database db = await openDatabase();
    result = (await db.query(table))
        .map<GameCard>((data) => GameCard.build(data))
        .toList();
    db.close();
    return result;
  }

  @override
  Future<int> save(List<GameCard> cards) async {
    int result = 0;
    Database db = await openDatabase();
    for (GameCard card in cards) {
      if (await db.insert(table, card.transform(),
              conflictAlgorithm: ConflictAlgorithm.replace) !=
          0) {
        result++;
      } else {
        break;
      }
    }
    db.close();
    return result;
  }
}
