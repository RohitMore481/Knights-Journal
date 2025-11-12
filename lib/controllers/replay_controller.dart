import 'package:flutter/material.dart';
import 'package:chess/chess.dart';

class ReplayController extends ChangeNotifier {
  final Chess game = Chess();
  int currentIndex = 0;
  List<String> pgnMoves = [];

  void setMoves(List<String> moves) {
    pgnMoves = moves;
    reset();
  }

  void reset() {
    game.reset();
    currentIndex = 0;
    notifyListeners();
  }

  void nextMove() {
    if (currentIndex < pgnMoves.length) {
      game.move(pgnMoves[currentIndex]);
      currentIndex++;
      notifyListeners();
    }
  }

  void prevMove() {
    if (currentIndex > 0) {
      game.undo();
      currentIndex--;
      notifyListeners();
    }
  }
}
