import 'package:flutter/material.dart';
import 'screens/add_sunset_screen.dart';
import 'models/sunset.dart';
import 'screens/detail_screen.dart';
import 'screens/auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SunsetDiaryApp());
}

class SunsetDiaryApp extends StatelessWidget {
  const SunsetDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunset Diary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF101827),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9955),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101827),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF222C3C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      initialRoute: '/',

      routes: {
        '/': (context) => const AuthScreen(),
        '/new': (context) => const AddSunsetScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          final sunset = settings.arguments as Sunset;

          return MaterialPageRoute(
            settings: settings,
            builder: (context) => DetailScreen(sunset: sunset),
          );
        }

        return null;
      },
    );
  }
}
