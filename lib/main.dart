import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `video_player` works on desktop.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weeaboo',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C2A),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false, // Hiding the debug banner
    );
  }
}