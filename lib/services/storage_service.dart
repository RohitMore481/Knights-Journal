import 'package:hive/hive.dart';
import '../models/game_model.dart';

class StorageService {
  static const String _boxName = 'gamesBox';

  static Future<void> init() async {
    Hive.registerAdapter(GameModelAdapter());
    await Hive.openBox<GameModel>(_boxName);
  }

  static Box<GameModel> get _box => Hive.box<GameModel>(_boxName);

  static List<GameModel> getGames() => _box.values.toList();

  static Future<void> addGame(GameModel game) async {
    await _box.add(game);
  }

  static Future<void> deleteGame(int index) async {
    await _box.deleteAt(index);
  }
}
