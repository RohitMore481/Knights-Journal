import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'scan_screen.dart';
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

  // State
  bool _isPressed = false;
  final List<String> _games = []; // Replace with Hive later

  @override
  void initState() {
    super.initState();

    // 🎬 Bottom bar slide-up animation
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

    // Start after a small delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });

    // 💫 Breathing glow animation
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

  // Navigate to dummy scan screen (temporary)
  void _onScanTap() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ScanScreen(),
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238), // Slate grey

      appBar: AppBar(
        title: const Text(
            "Knight’s Journal",
            style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            ),
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


      // Journal list or empty screen
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _games.isEmpty ? _buildEmptyState() : _buildGameList(),
      ),

      // 🟡 Breathing glowing floating action button
      floatingActionButton: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _onScanTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
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
              child: AnimatedScale(
                scale: _isPressed ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: FloatingActionButton(
                  heroTag: 'scan_button',
                  onPressed: _onScanTap,
                  backgroundColor: Colors.amber,
                  shape: const CircleBorder(),
                  elevation: _isPressed ? 2 : 8,
                  child: const Icon(Icons.camera_alt, size: 32, color: Colors.black),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ⚫ Bottom navigation bar slide-up animation
      bottomNavigationBar: SlideTransition(
        position: _bottomBarOffset,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: const Color(0xFF37474F),
          height: 58,
          child: const SizedBox(), // Clean, minimalist bottom bar
        ),
      ),
    );
  }

  // 🧩 Builds empty journal UI
  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            FaIcon(FontAwesomeIcons.chessKnight, color: Colors.amber, size: 90),
            SizedBox(height: 16),
            Text(
              "Your journal is empty",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "Tap the knight below to scan a scoresheet",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ♟️ Builds animated list of games
  Widget _buildGameList() {
    return ListView.builder(
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];
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
                game,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Tap to replay game",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Dummy scan screen (temporary placeholder)
class DummyScanScreen extends StatelessWidget {
  const DummyScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        title: const Text("Scan Scoresheet", style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Hero(
          tag: 'scan_button',
          child: Icon(Icons.camera_alt, size: 80, color: Colors.amber),
        ),
      ),
    );
  }
}
