import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hive/hive.dart';
import 'package:knights_journal/ui/replay_screen.dart';
import 'package:knights_journal/ui/home_screen.dart';
import 'package:knights_journal/models/game_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  final List<Map<String, String>> _moves = [];
  bool _isLoading = false;

  /// ---------------------------------------
  /// NEW: Convert white/black rows → SAN list
  /// ---------------------------------------
  List<String> _flattenMovesToSan() {
    List<String> san = [];
    for (var m in _moves) {
      if ((m["white"] ?? "").isNotEmpty) san.add(m["white"]!.trim());
      if ((m["black"] ?? "").isNotEmpty) san.add(m["black"]!.trim());
    }
    return san;
  }

  /// ---------------------------------------
  /// Move validation
  /// ---------------------------------------
  bool _isValidMove(String move) {
    final s = move.trim();
    if (s.isEmpty) return false;

    String m = s.replaceAll('0-0-0', 'O-O-O').replaceAll('0-0', 'O-O');
    m = m.replaceAll('o-o-o', 'O-O-O').replaceAll('o-o', 'O-O');
    m = m.replaceAll('0', 'O');
    m = m.replaceAll(RegExp(r'\s+'), '');

    final regex = RegExp(
      r'^('
      r'O-O(-O)?'
      r'|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](=[QRBN])?'
      r'|[a-h]x[a-h][1-8](=[QRBN])?'
      r'|[a-h][1-8]'
      r')[\+#]?$',
      caseSensitive: false,
    );

    return regex.hasMatch(m);
  }

  /// ---------------------------------------
  /// Image picking / cropping
  /// ---------------------------------------
  Future<void> _showImagePicker({bool append = false}) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF37474F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.amber),
              title: const Text("Capture with Camera",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _captureImage(append: append);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.amber),
              title: const Text("Choose from Gallery",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(append: append);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage({bool append = false}) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Scoresheet',
            toolbarColor: const Color(0xFF37474F),
            toolbarWidgetColor: Colors.amber,
          ),
        ],
      );

      File file;
      if (cropped != null) {
        final newPath =
            '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final newFile = await File(cropped.path).copy(newPath);
        file = newFile;
      } else {
        file = File(picked.path);
      }

      if (!append) _selectedImages.clear();
      _selectedImages.add(file);

      setState(() => _isLoading = true);
      await _processOCR();
    } catch (e) {
      debugPrint("Camera error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery({bool append = false}) async {
    try {
      final files = await _picker.pickMultiImage();
      if (files.isEmpty) return;

      if (!append) _selectedImages.clear();

      for (final image in files) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: image.path,
          compressQuality: 95,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Scoresheet',
              toolbarColor: const Color(0xFF37474F),
              toolbarWidgetColor: Colors.amber,
            ),
          ],
        );

        File file;
        if (cropped != null) {
          final newPath =
              '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          file = await File(cropped.path).copy(newPath);
        } else {
          file = File(image.path);
        }

        _selectedImages.add(file);
      }

      setState(() => _isLoading = true);
      await _processOCR();
    } catch (e) {
      debugPrint("Gallery error: $e");
      setState(() => _isLoading = false);
    }
  }

  /// ---------------------------------------
  /// OCR processing + parsing
  /// ---------------------------------------
  Future<void> _processOCR() async {
    setState(() => _isLoading = true);

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    List<String> allTokens = [];

    try {
      for (var file in _selectedImages) {
        final inputImage = InputImage.fromFile(file);
        final recognized = await recognizer.processImage(inputImage);

        debugPrint("🔍 OCR Output for ${file.path}:\n${recognized.text}");

        final text = recognized.text.replaceAll('\r', ' ');
        final tokens = text
            .split(RegExp(r'\s+'))
            .where((t) => t.trim().isNotEmpty)
            .map((t) => t.replaceAll(RegExp(r'[^\wO0\-\+\#=\.]'), ''))
            .where((t) => t.trim().isNotEmpty)
            .toList();

        allTokens.addAll(tokens);
      }

      recognizer.close();

      if (allTokens.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("No text detected. Try cropping or clearer image.")),
        );
        return;
      }

      int mid = (allTokens.length / 2).floor();
      bool looksLikeStacked = false;

      final movePattern = RegExp(
          r'^[KQRBN]?[a-h]?[1-8]?[x\-]?[a-h][1-8](=?[QRBN])?[\+#]?$|^O-?O(-?O)?$',
          caseSensitive: false);

      int valid1 =
          allTokens.take(mid).where((m) => movePattern.hasMatch(m)).length;
      int valid2 =
          allTokens.skip(mid).where((m) => movePattern.hasMatch(m)).length;

      if (valid1 > 1 && valid2 > 1) looksLikeStacked = true;

      List<Map<String, String>> parsed = [];

      if (looksLikeStacked) {
        final whiteMoves = allTokens.take(mid).toList();
        final blackMoves = allTokens.skip(mid).toList();

        for (int i = 0; i < whiteMoves.length; i++) {
          final w = whiteMoves[i];
          final b = i < blackMoves.length ? blackMoves[i] : "";
          parsed.add({
            "white": w,
            "black": b,
            "white_valid": _isValidMove(w).toString(),
            "black_valid": _isValidMove(b).toString(),
          });
        }
      } else {
        for (int i = 0; i < allTokens.length; i += 2) {
          final w = allTokens[i];
          final b = (i + 1 < allTokens.length) ? allTokens[i + 1] : "";
          parsed.add({
            "white": w,
            "black": b,
            "white_valid": _isValidMove(w).toString(),
            "black_valid": _isValidMove(b).toString(),
          });
        }
      }

      setState(() {
        _moves
          ..clear()
          ..addAll(parsed);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("OCR failed: $e");
      setState(() => _isLoading = false);
    }
  }

  /// ---------------------------------------
  /// Build UI
  /// ---------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      appBar: AppBar(
        title:
            const Text("Scan Scoresheet", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF37474F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 12),
                    Text("Processing...", style: TextStyle(color: Colors.white70))
                  ],
                ),
              )
            : _moves.isEmpty
                ? const Center(
                    child: Text(
                      "No scoresheets yet.\nCapture or select from gallery to begin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                          child: SingleChildScrollView(
                              child: Center(child: _buildMovesTable()))),
                      const SizedBox(height: 24),

                      /// ---------------------------------------
                      /// VERIFY → GO TO REPLAY SCREEN (UNSAVED MODE)
                      /// ---------------------------------------
                      ElevatedButton.icon(
                        onPressed: () async {
                          bool hasInvalid = _moves.any((m) =>
                              (m["white_valid"] ?? "false") == "false" ||
                              (m["black_valid"] ?? "false") == "false");

                          if (hasInvalid) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF37474F),
                                title: const Text("Invalid Moves Detected",
                                    style: TextStyle(color: Colors.white)),
                                content: const Text(
                                  "Some moves look incorrect. Please correct highlighted cells before proceeding.",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK",
                                        style: TextStyle(color: Colors.amber)),
                                  )
                                ],
                              ),
                            );
                          } else {
                            final movesSan = _flattenMovesToSan();

                            // Open ReplayScreen in UNSAVED mode:
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReplayScreen(
                                  game: null, // unsaved
                                  index: null,
                                  movesFromScan: movesSan,
                                ),
                              ),
                            );

                            // If user saved from metadata → go to Home and refresh
                            if (result != null && result['saved'] == true) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const HomeScreen()),
                                (route) => false,
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.arrow_forward, color: Colors.black),
                        label: const Text("Next: Replay Moves",
                            style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                      ),

                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _showImagePicker(append: true),
                        icon: const Icon(Icons.add, color: Colors.amber),
                        label: const Text("Add another scoresheet",
                            style: TextStyle(color: Colors.amber)),
                      ),
                      const SizedBox(height: 70),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImagePicker,
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.camera_alt, color: Colors.black),
        label: const Text("Scan Scoresheet",
            style: TextStyle(color: Colors.black)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// ---------------------------------------
  /// Editable table UI
  /// ---------------------------------------
  Widget _buildMovesTable() {
    return Table(
      border: TableBorder.all(color: Colors.white30),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFF455A64)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text("White",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text("Black",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var move in _moves)
          TableRow(children: [
            _editableCell(move, "white"),
            _editableCell(move, "black"),
          ]),
      ],
    );
  }

  Widget _editableCell(Map<String, String> move, String color) {
    final value = move[color] ?? "";
    final validFlag = move["${color}_valid"] ?? "false";
    final isValid = validFlag == "true";

    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        initialValue: value,
        onChanged: (val) {
          move[color] = val;
          move["${color}_valid"] = _isValidMove(val).toString();
          setState(() {});
        },
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          enabledBorder: isValid
              ? InputBorder.none
              : OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
          focusedBorder: isValid
              ? InputBorder.none
              : OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2.5),
                  borderRadius: BorderRadius.circular(6),
                ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        ),
      ),
    );
  }
}
