import 'package:flutter/material.dart';

class MetadataScreen extends StatefulWidget {
  final List<String> movesSan;

  const MetadataScreen({super.key, required this.movesSan});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  final TextEditingController whiteController =
      TextEditingController(text: "Player 1");
  final TextEditingController blackController =
      TextEditingController(text: "Player 2");
  final TextEditingController eventController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String selectedResult = "*";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Game Details", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.amber),
            onPressed: () {
              final metadata = {
                "white": whiteController.text.trim(),
                "black": blackController.text.trim(),
                "event": eventController.text.trim(),
                "location": locationController.text.trim(),
                "date": dateController.text.trim(),
                "notes": notesController.text.trim(),
                "result": selectedResult,
              };

              Navigator.pop(context, metadata);
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 3),
              )
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- RESULT SELECTOR ----------------
              const Text("Result",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              Wrap(
                spacing: 12,
                children: [
                  _buildResultChip("1-0"),
                  _buildResultChip("0-1"),
                  _buildResultChip("1/2-1/2"),
                  _buildResultChip("*"),
                ],
              ),

              const SizedBox(height: 22),

              // ---------------- FORM FIELDS ----------------
              _inputField("White Player", whiteController),
              _inputField("Black Player", blackController),
              _inputField("Event (Optional)", eventController),
              _inputField("Location (Optional)", locationController),

              _datePickerField(),

              const SizedBox(height: 14),

              _notesField(),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------- UI Components -----------------------------

  Widget _inputField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.black), // text inside field black
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _notesField() {
    return TextField(
      controller: notesController,
      maxLines: 4,
      style: const TextStyle(color: Colors.black),
      decoration: const InputDecoration(
        labelText: "Notes (Optional)",
        labelStyle: TextStyle(color: Colors.black87),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget _datePickerField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: dateController,
        readOnly: true,
        style: const TextStyle(color: Colors.black),
        decoration: const InputDecoration(
          labelText: "Date (Optional)",
          labelStyle: TextStyle(color: Colors.black87),
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_month, color: Colors.black87),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
        onTap: () async {
          final today = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            initialDate: today,
          );
          if (picked != null) {
            dateController.text =
                "${picked.year}-${picked.month}-${picked.day}";
          }
        },
      ),
    );
  }

  // ----------------------------- RESULT CHIP -----------------------------

  Widget _buildResultChip(String result) {
    final bool selected = selectedResult == result;

    return ChoiceChip(
      label: Text(
        result,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: selected,
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.grey.shade300,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? Colors.blueAccent : Colors.grey.shade500,
          width: selected ? 2.0 : 1,
        ),
      ),
      onSelected: (_) {
        setState(() => selectedResult = result);
      },
    );
  }
}
