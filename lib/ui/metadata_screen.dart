import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:knights_journal/models/game_model.dart';

class MetadataScreen extends StatefulWidget {
  final List<String> movesSan;
  final GameModel? existingGame; // null = new game
  final int? index; // null or -1 = unsaved game

  const MetadataScreen({
    super.key,
    required this.movesSan,
    this.existingGame,
    this.index,
  });

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController whiteCtrl;
  late TextEditingController blackCtrl;
  late TextEditingController eventCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController dateCtrl;
  late TextEditingController notesCtrl;

  String selectedResult = "*";

  bool get isEditing =>
      widget.existingGame != null &&
      widget.index != null &&
      widget.index! >= 0;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final g = widget.existingGame!;
      whiteCtrl = TextEditingController(text: g.white);
      blackCtrl = TextEditingController(text: g.black);
      eventCtrl = TextEditingController(text: g.event);
      locationCtrl = TextEditingController(text: g.location);
      dateCtrl = TextEditingController(text: g.date);
      notesCtrl = TextEditingController(text: g.notes);
      selectedResult = g.result;
    } else {
      whiteCtrl = TextEditingController(text: "Player 1");
      blackCtrl = TextEditingController(text: "Player 2");
      eventCtrl = TextEditingController();
      locationCtrl = TextEditingController();
      dateCtrl = TextEditingController();
      notesCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    whiteCtrl.dispose();
    blackCtrl.dispose();
    eventCtrl.dispose();
    locationCtrl.dispose();
    dateCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  // --------------------------
  // SAVE GAME
  // --------------------------
  Future<void> _saveGame() async {
    final box = Hive.box<GameModel>('games');

    final game = GameModel(
      white: whiteCtrl.text.trim().isEmpty ? "Player 1" : whiteCtrl.text.trim(),
      black: blackCtrl.text.trim().isEmpty ? "Player 2" : blackCtrl.text.trim(),
      event: eventCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      date: dateCtrl.text.trim(),
      result: selectedResult,
      notes: notesCtrl.text.trim(),
      movesSan: widget.movesSan,
      pgn: _generatePgn(),
    );

    if (isEditing) {
      await box.putAt(widget.index!, game);
      Navigator.pop(context, {"updated": true});
    } else {
      await box.add(game);
      Navigator.pop(context, {"saved": true});
    }
  }

  // --------------------------
  // DELETE GAME (only if editing)
  // --------------------------
  Future<void> _deleteGame() async {
    if (!isEditing) return;

    final box = Hive.box<GameModel>('games');

    // confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF37474F),
        title: const Text("Delete Game?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "This will permanently remove the game.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.amber)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final key = box.keyAt(widget.index!);
      await box.delete(key);
      Navigator.pop(context, {"deleted": true});
    } catch (e) {
      debugPrint("Delete failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete game.")),
      );
    }
  }

  // --------------------------
  // PGN builder
  // --------------------------
  String _generatePgn() {
    final b = StringBuffer();

    b.writeln('[White "${whiteCtrl.text}"]');
    b.writeln('[Black "${blackCtrl.text}"]');
    if (eventCtrl.text.isNotEmpty) b.writeln('[Event "${eventCtrl.text}"]');
    if (locationCtrl.text.isNotEmpty) b.writeln('[Site "${locationCtrl.text}"]');
    if (dateCtrl.text.isNotEmpty) b.writeln('[Date "${dateCtrl.text}"]');
    b.writeln('[Result "$selectedResult"]');
    b.writeln("");

    for (int i = 0; i < widget.movesSan.length; i += 2) {
      final w = widget.movesSan[i];
      final bMove = i + 1 < widget.movesSan.length ? widget.movesSan[i + 1] : "";
      b.write("${(i ~/ 2) + 1}. $w $bMove ");
    }
    b.write(selectedResult);

    return b.toString();
  }

  // --------------------------
  // UI
  // --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      appBar: AppBar(
        title: Text(isEditing ? "Edit Game" : "Save Game"),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteGame,
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _field("White Player", whiteCtrl),
            _field("Black Player", blackCtrl),
            _field("Event", eventCtrl),
            _field("Location", locationCtrl),
            _field("Date", dateCtrl),
            _field("Notes", notesCtrl, maxLines: 3),

            const SizedBox(height: 14),
            _buildResultSelector(),
            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: _saveGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
              ),
              child: Text(isEditing ? "Update Game" : "Save Game"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF37474F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSelector() {
    const results = ["1-0", "0-1", "1/2-1/2", "*"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Result", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: results.map((r) => _resultButton(r)).toList(),
        ),
      ],
    );
  }

  Widget _resultButton(String value) {
    final selected = selectedResult == value;

    return GestureDetector(
      onTap: () => setState(() => selectedResult = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : const Color(0xFF455A64),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.amberAccent : Colors.white30,
            width: 2,
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
