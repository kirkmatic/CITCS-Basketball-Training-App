import 'package:citcs_training_app/screens/coach_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:citcs_training_app/screens/login_screen.dart';
import 'package:citcs_training_app/screens/players_screen.dart';
import 'package:citcs_training_app/screens/signup_screen.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    // Check if we are running on the web
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBTE09LR6BZb4FFQQea1dX0qSKEyvQbayU",
          authDomain: "citcs-training-app.firebaseapp.com",
          projectId: "citcs-training-app",
          storageBucket: "citcs-training-app.appspot.com",
          messagingSenderId: "1067520972977",
          appId: "1:1067520972977:web:e19a3773961695a6bb2a90",
          measurementId: "G-GY155J4MY8",
        ),
      );
    } else {
      // For mobile platforms, Firebase.initializeApp() will use the default settings from google-services.json or GoogleService-Info.plist
      await Firebase.initializeApp();
    }
    runApp(const MyApp());
  } catch (e) {
    // Handle initialization error
    debugPrint("Error initializing Firebase: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CITCS Training App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        // Define the routes for your app
        '/login': (context) => const LoginPageWidget(),
        '/player': (context) => PlayersPageWidget(), 
        '/signup': (context) => const SignupPageWidget(),
        '/coach': (context) => const CoachesPageWidget(),
      },
    );
  }
}