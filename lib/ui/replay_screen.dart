import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:knights_journal/controllers/replay_controller.dart';
import 'package:knights_journal/models/game_model.dart';
import 'package:knights_journal/widgets/chess_board_viewer.dart';
import 'package:knights_journal/widgets/replay_controls.dart';
import 'package:knights_journal/ui/metadata_screen.dart';

class ReplayScreen extends StatelessWidget {
  final GameModel? game; // null = unsaved
  final int? index; // null = unsaved
  final List<String>? movesFromScan; // when coming directly from ScanScreen

  const ReplayScreen({
    super.key,
    this.game,
    this.index,
    this.movesFromScan,
  });

  bool get isNewGame => game == null;

  @override
  Widget build(BuildContext context) {
    // Defensive: allow both sources
    final moves = movesFromScan ?? game?.movesSan ?? <String>[];

    return ChangeNotifierProvider(
      create: (_) => ReplayController()..setMoves(moves),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(isNewGame ? "Replay & Save" : "Replay Game"),
          actions: [
            // NEW UNSAVED GAME → SHOW SAVE BUTTON
            if (isNewGame)
              IconButton(
                icon: const Icon(Icons.save, color: Colors.amber),
                tooltip: "Save Game",
                onPressed: () => _openMetadata(context, moves),
              ),

            // EXISTING GAME → SHOW INFO BUTTON
            if (!isNewGame)
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.amber),
                tooltip: "Edit Game",
                onPressed: () => _openMetadata(context, moves),
              ),
          ],
        ),

        body: Column(
          children: [
            Expanded(
              child: Consumer<ReplayController>(
                builder: (_, rc, __) {
                  return ChessBoardViewer(game: rc.game);
                },
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Consumer<ReplayController>(
                builder: (_, rc, __) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: rc.pgnMoves.length,
                    itemBuilder: (context, i) {
                      return Text(
                        rc.pgnMoves[i],
                        style: TextStyle(
                          color: i == rc.currentIndex
                              ? Colors.amber
                              : Colors.white70,
                          fontSize: 16,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Consumer<ReplayController>(
              builder: (_, rc, __) {
                return ReplayControls(
                  onStart: rc.reset,
                  onPrev: rc.prevMove,
                  onNext: rc.nextMove,
                  onEnd: () {
                    while (rc.currentIndex < rc.pgnMoves.length - 1) {
                      rc.nextMove();
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // ---------------------------
  // OPEN METADATA SCREEN
  // ---------------------------
  Future<void> _openMetadata(BuildContext context, List<String> moves) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MetadataScreen(
          movesSan: moves,
          existingGame: game,
          index: index,
        ),
      ),
    );

    if (result == null) return;

    // Saved New Game -> bubble up so caller (ScanScreen) can redirect to Home
    if (result["saved"] == true) {
      Navigator.pop(context, {"saved": true});
      return;
    }

    // Edited Existing Game -> inform caller (HomeScreen) to refresh
    if (result["updated"] == true) {
      Navigator.pop(context, {"updated": true});
      return;
    }

    // Deleted Existing Game -> inform caller (HomeScreen) to refresh/remove
    if (result["deleted"] == true) {
      Navigator.pop(context, {"deleted": true});
      return;
    }
  }
}
