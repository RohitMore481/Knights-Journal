import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:knights_journal/ui/scan_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      appBar: AppBar(
        title: const Text(
          "Learn Chess Notation",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF37474F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📖 About Chess Notation",
              style: TextStyle(
                fontSize: 20,
                color: Colors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Chess notation is a way to record moves using letters and numbers. "
              "Each piece is represented by an initial (K=King, Q=Queen, R=Rook, B=Bishop, N=Knight). "
              "The board’s columns (a–h) and rows (1–8) define squares.",
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 20),

            const Text(
              "♟️ Common Examples",
              style: TextStyle(
                fontSize: 18,
                color: Colors.amber,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            _buildExample("e4", "Pawn moves to e4 square."),
            _buildExample("Nf3", "Knight moves to f3."),
            _buildExample("O-O", "Kingside Castling."),
            _buildExample("exd5", "Pawn on e-file captures on d5."),
            _buildExample("Qh5+", "Queen moves to h5 and gives check."),
            _buildExample("Rxf7#", "Rook captures on f7 for checkmate."),

            const SizedBox(height: 25),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 20),

            const Text(
              "🧾 Sample Scoresheet",
              style: TextStyle(
                fontSize: 20,
                color: Colors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Below is a sample chess scoresheet you can try scanning.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 15),

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                "assets/sample_scoresheet.png", // Make sure this file exists!
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  shadowColor: Colors.amberAccent,
                ),
                onPressed: () {
                  Navigator.of(context).push(PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 400),
                    pageBuilder: (_, __, ___) => const ScanScreen(),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ));
                },
                icon: const Icon(FontAwesomeIcons.camera, size: 18),
                label: const Text(
                  "Open Scanner",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildExample(String notation, String meaning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notation.padRight(6),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              meaning,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
