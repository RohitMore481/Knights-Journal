import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:knights_journal/controllers/replay_controller.dart';
import 'package:knights_journal/widgets/chess_board_viewer.dart';
import 'package:knights_journal/widgets/replay_controls.dart';
import 'package:knights_journal/ui/metadata_screen.dart';


class ReplayScreen extends StatelessWidget {
  final List<String> moves;

  const ReplayScreen({super.key, required this.moves});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReplayController()..setMoves(moves),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("Replay Moves", style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.amber),
              tooltip: "Save & Add Metadata",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MetadataScreen(movesSan: moves),
                  ),
                );
              },
            ),
          ],
        ),

        body: Column(
          children: [

            // ---------------------- CHESSBOARD ----------------------
            Expanded(
              flex: 4,
              child: Consumer<ReplayController>(
                builder: (context, rc, _) {
                  return ChessBoardViewer(game: rc.game);
                },
              ),
            ),

            // ----------------------- MOVE LIST -----------------------
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade900,
                child: ListView.builder(
                  itemCount: (moves.length / 2).ceil(),
                  itemBuilder: (_, index) {
                    int w = index * 2;
                    int b = w + 1;

                    String white = moves[w];
                    String black = b < moves.length ? moves[b] : "";

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text("${index + 1}. ",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(white,
                              style: const TextStyle(
                                  color: Colors.amber, fontSize: 16)),
                          const SizedBox(width: 12),
                          Text(black,
                              style: const TextStyle(
                                  color: Colors.lightGreenAccent, fontSize: 16)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ----------------------- CONTROLS ------------------------
            Consumer<ReplayController>(
              builder: (context, rc, _) {
                return ReplayControls(
                  onStart: rc.reset,
                  onPrev: rc.prevMove,
                  onNext: rc.nextMove,
                  onEnd: () {
                    while (rc.currentIndex < rc.pgnMoves.length) {
                      rc.nextMove();
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
