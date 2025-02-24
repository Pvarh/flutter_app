import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/recept_provider.dart';
import 'screens/home_screen.dart';
import 'dart:ui'; // Import for ImageFilter

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReceptProvider()), // State management for recipes
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receptár', // App title
      debugShowCheckedModeBanner: false, // Remove debug banner in the top-right corner
      theme: ThemeData(
        // Customize the theme
        colorScheme: ThemeData().colorScheme.copyWith(
              primary: const Color.fromARGB(255, 204, 204, 204), // Primary color
              secondary: const Color.fromARGB(255, 233, 118, 11), // Accent color
              surface: const Color.fromARGB(210, 214, 214, 214), // Surface color
              onSurface: const Color.fromARGB(255, 43, 40, 40), // Text color on surface
            ),
        // Add more theme customizations if needed
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Make AppBar background transparent
          elevation: 0, // Remove shadow
          titleTextStyle: TextStyle(
            color: Colors.white, // AppBar title text color
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white), // Default text color
          bodyMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
      ),
      home: const HomeScreen(), // Set the home screen
    );
  }
}