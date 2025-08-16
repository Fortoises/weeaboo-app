import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Load the .env file
  await dotenv.load(fileName: ".env");
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