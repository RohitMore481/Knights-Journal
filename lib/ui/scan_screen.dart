import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hive/hive.dart';

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

        // Optional crop before OCR
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
        // 🔧 Create a safe copy in your app's directory for MLKit
        final newPath = '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
        // Optional: crop each image before OCR
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
          final newPath = '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
    }
  }


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
            .whereType<String>()
            .where((t) => t.trim().isNotEmpty)
            .map((t) => t.replaceAll(RegExp(r'[^\wO0\-\+\#=]'), ''))
            .toList();

        allTokens.addAll(tokens);
      }

      recognizer.close();

      if (allTokens.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No text detected. Try cropping or clearer image.")),
        );
        return;
      }

      // 🔧 Smart alignment: detect if OCR listed all whites first, then blacks
      int mid = (allTokens.length / 2).floor();
      bool looksLikeStacked = false;

      // If first half are all valid chess moves and second half are too → likely vertical layout
      final movePattern = RegExp(r'^[KQRBN]?[a-h]?[1-8]?[x\-]?[a-h][1-8](=?[QRBN])?[\+#]?$|^O-?O(-?O)?$',
          caseSensitive: false);
      int valid1 = allTokens.take(mid).where((m) => movePattern.hasMatch(m)).length;
      int valid2 = allTokens.skip(mid).where((m) => movePattern.hasMatch(m)).length;

      if (valid1 > 1 && valid2 > 1) looksLikeStacked = true;

      List<Map<String, String>> parsed = [];

      if (looksLikeStacked) {
        // e.g. [e4, Nf3, Bb6, e5, Nc6, a6]
        // → Pair top half vs bottom half
        final whiteMoves = allTokens.take(mid).toList();
        final blackMoves = allTokens.skip(mid).toList();

        for (int i = 0; i < whiteMoves.length; i++) {
          parsed.add({
            "white": whiteMoves[i],
            "black": i < blackMoves.length ? blackMoves[i] : "",
          });
        }
      } else {
        // Default sequential pairing
        for (int i = 0; i < allTokens.length; i += 2) {
          parsed.add({
            "white": allTokens[i],
            "black": (i + 1 < allTokens.length) ? allTokens[i + 1] : "",
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



  Future<void> _saveGame() async {
    final box = await Hive.openBox('games');
    await box.add(_moves);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Game saved successfully!"),
    ));
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF37474F),
        title: const Text("Verify Extracted Moves",
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: _buildMovesTable()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.amber))),
          ElevatedButton(
            onPressed: () async {
              await _saveGame();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

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
                  style: TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text("Black",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        initialValue: move[color] ?? "",
        onChanged: (val) => move[color] = val,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      appBar: AppBar(
        title: const Text("Scan Scoresheet", style: TextStyle(color: Colors.white)),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                          child: SingleChildScrollView(
                              child: Center(child: _buildMovesTable()))),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showVerificationDialog,
                        icon: const Icon(Icons.check, color: Colors.black),
                        label: const Text("Verify & Save",
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
}
