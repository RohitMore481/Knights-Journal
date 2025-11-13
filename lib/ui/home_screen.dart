import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'replay_screen.dart';
import 'scan_screen.dart';
import '../models/game_model.dart';
import 'learn_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Animations
  late AnimationController _controller;
  late Animation<Offset> _bottomBarOffset;

  // Glow animation
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Ensure box is open (safe to call again)
    Hive.openBox<GameModel>('games');

    // Bottom bar animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bottomBarOffset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });

    // Breathing glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // Navigation to Scan
  void _onScanTap() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ScanScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),

      appBar: AppBar(
        title: const Text(
          "Knight’s Journal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF37474F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.amber),
            tooltip: "Learn Chess Notation",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LearnScreen()),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),

        // LIVE LISTENER FOR HIVE
        child: ValueListenableBuilder(
          valueListenable: Hive.box<GameModel>('games').listenable(),
          builder: (_, Box<GameModel> box, __) {
            if (box.isEmpty) {
              return _buildEmptyState();
            }

            return _buildGameList(box);
          },
        ),
      ),

      // Floating scan button
      floatingActionButton: GestureDetector(
        onTapDown: (_) => setState(() {}),
        onTapUp: (_) => _onScanTap(),
        onTapCancel: () => setState(() {}),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(_glowAnimation.value),
                    blurRadius: 25 + (_glowAnimation.value * 10),
                    spreadRadius: 3 + (_glowAnimation.value * 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'scan_button',
                onPressed: _onScanTap,
                backgroundColor: Colors.amber,
                shape: const CircleBorder(),
                elevation: 8,
                child: const Icon(Icons.camera_alt, size: 32, color: Colors.black),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: SlideTransition(
        position: _bottomBarOffset,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: const Color(0xFF37474F),
          height: 58,
          child: const SizedBox(),
        ),
      ),
    );
  }

  // ------------------- EMPTY STATE -------------------
  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            FaIcon(FontAwesomeIcons.chessKnight, color: Colors.amber, size: 90),
            SizedBox(height: 16),
            Text("Your journal is empty",
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 8),
            Text("Tap the knight below to scan a scoresheet",
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ------------------- GAME LIST -------------------
  Widget _buildGameList(Box<GameModel> box) {
    return ListView.builder(
      itemCount: box.length,
      itemBuilder: (context, index) {
        final game = box.get(index);

        // If entry was deleted or is null → skip it safely
        if (game == null) {
          return const SizedBox.shrink();
        }

        final white = game.white.isNotEmpty ? game.white : "White";
        final black = game.black.isNotEmpty ? game.black : "Black";
        final event = game.event.isNotEmpty ? game.event : "Friendly Game";
        final result = game.result.isNotEmpty ? game.result : "*";

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: child,
              ),
            );
          },
          child: Card(
            color: const Color(0xFF455A64),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.chessKnight,
                color: Colors.amber,
                size: 24,
              ),
              title: Text(
                "$white vs $black",
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "$event • $result",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              // OPEN REPLAY SCREEN (SAVED MODE) and await result
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReplayScreen(
                      game: game,
                      index: index,
                    ),
                  ),
                );

                // If update/delete happened, ValueListenableBuilder will also rebuild,
                // but call setState to be safe (keeps animations consistent).
                if (result != null &&
                    (result['updated'] == true || result['deleted'] == true)) {
                  setState(() {});
                }
              },
            ),
          ),
        );
      },
    );
  }
}
