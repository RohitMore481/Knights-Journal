import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess;

class ChessBoardViewer extends StatefulWidget {
  final chess.Chess game;

  const ChessBoardViewer({super.key, required this.game});

  @override
  State<ChessBoardViewer> createState() => _ChessBoardViewerState();
}

class _ChessBoardViewerState extends State<ChessBoardViewer> {
  final ChessBoardController controller = ChessBoardController();

  @override
  void initState() {
    super.initState();
    controller.loadFen(widget.game.fen);
  }

  @override
  void didUpdateWidget(covariant ChessBoardViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.loadFen(widget.game.fen);
  }

  @override
  Widget build(BuildContext context) {
    controller.loadFen(widget.game.fen);

    return ChessBoard(
      controller: controller,
      enableUserMoves: false,
      boardColor: BoardColor.brown,
    );
  }
}
