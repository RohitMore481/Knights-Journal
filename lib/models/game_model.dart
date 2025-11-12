import 'package:hive/hive.dart';

part 'game_model.g.dart'; // generated adapter

@HiveType(typeId: 0)
class GameModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String pgn;

  @HiveField(2)
  DateTime date;

  GameModel({
    required this.title,
    required this.pgn,
    required this.date,
  });
}
