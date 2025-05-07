import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:steel/home_page.dart';
import 'package:steel/registration_page.dart';
import 'package:steel/splash_screen.dart'; // Import the SplashScreen
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      initialRoute: '/splash', // Set splash screen as the initial route
      routes: {
        '/splash': (context) => const SplashScreen(), // SplashScreen route
        '/login': (context) => const LoginPage(), // Login route
        '/home': (context) => const MyHomePage(), // Home route
        '/register': (context) => const RegisterPage(), // Registration route
      },
    );
  }
}
