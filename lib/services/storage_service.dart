import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_model.dart';

class StorageService {
  static Future<void> init() async {
    // REGISTER ADAPTER
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GameModelAdapter());
    }

    // OPEN BOX
    await Hive.openBox<GameModel>('games');
  }
}
