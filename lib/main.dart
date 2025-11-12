import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/game_model.dart';
import 'services/storage_service.dart';
import 'ui/home_screen.dart';
import 'utils/theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.init();

  runApp(const KnightsJournalApp());
}

class KnightsJournalApp extends StatelessWidget {
  const KnightsJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Knight's Journal",
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFF263238),
        primaryColor: Colors.amber,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF37474F),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: Colors.amber),
        ),
        dialogTheme: const DialogThemeData( // ✅ fixed line
          backgroundColor: Color(0xFF37474F),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          contentTextStyle: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          labelLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.amber,
          contentTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          behavior: SnackBarBehavior.floating,
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
