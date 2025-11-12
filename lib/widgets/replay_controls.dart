import 'package:flutter/material.dart';

class ReplayControls extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onEnd;

  const ReplayControls({
    super.key,
    required this.onStart,
    required this.onPrev,
    required this.onNext,
    required this.onEnd,
  });

  Widget controlButton(IconData icon, VoidCallback action) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          controlButton(Icons.first_page, onStart),
          controlButton(Icons.chevron_left, onPrev),
          controlButton(Icons.chevron_right, onNext),
          controlButton(Icons.last_page, onEnd),
        ],
      ),
    );
  }
}
