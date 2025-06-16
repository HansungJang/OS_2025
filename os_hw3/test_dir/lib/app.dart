// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'app_state.dart'; // Import ApplicationState
import 'Home.dart'; // HomePage
import 'about_us.dart'; // AboutPage
import 'therapist_page.dart'; // TherapistPage
import 'therapy_area.dart'; // TherapyPage
import 'consultation_page.dart'; // ConsultationPage
import 'location.dart'; // LocationPage
import 'login.dart'; // Import LoginPage


class MindRestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);

    return MaterialApp(
      title: 'Mind Rest',
      theme: ThemeData(
        primaryColor: const Color(0xFF7D9D81),
        scaffoldBackgroundColor: const Color(0xFFF7F7F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7D9D81),
          background: const Color(0xFFF7F7F1),
          primary: const Color(0xFF7D9D81),
          secondary: const Color(0xFFE6EAE4),
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF4B5F4A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE6EAE4),
          foregroundColor: Color(0xFF4B5F4A),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF4B5F4A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF4B5F4A),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          color: Colors.white.withOpacity(0.85),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7D9D81),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: appState.user == null ? const LoginPage() : HomePage(),
      routes: {
        '/home': (context) => HomePage(),
        '/about': (context) => const AboutPage(),
        '/therapist': (context) => const TherapistPage(),
        '/therapyarea': (context) => const TherapyPage(),
        '/consultation': (context) => const ConsultationPage(),
        '/location': (context) => const LocationPage(),
      },
    );
  }
  }