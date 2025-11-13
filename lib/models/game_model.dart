import 'package:hive/hive.dart';

part 'game_model.g.dart';

@HiveType(typeId: 1)
class GameModel {
  @HiveField(0)
  String white;

  @HiveField(1)
  String black;

  @HiveField(2)
  String event;

  @HiveField(3)
  String location;

  @HiveField(4)
  String date;

  @HiveField(5)
  String notes;

  @HiveField(6)
  String result;

  @HiveField(7)
  List<String> movesSan;

  @HiveField(8)
  String pgn;

  GameModel({
    required this.white,
    required this.black,
    required this.event,
    required this.location,
    required this.date,
    required this.notes,
    required this.result,
    required this.movesSan,
    required this.pgn,
  });
}
