import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/recept_provider.dart';
import 'screens/home_screen.dart';

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
              primary: const Color.fromARGB(255, 255, 255, 255), // Primary color
              secondary: const Color.fromARGB(255, 233, 118, 11), // Accent color
              surface: const Color.fromARGB(210, 255, 255, 255), // Surface color
              onSurface: const Color.fromARGB(255, 166, 166, 166), // Text color on surface
            ),
        // Add more theme customizations if needed
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(200, 0, 0, 0), // AppBar background color
          titleTextStyle: TextStyle(
            color: Colors.white, // AppBar title text color
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white), // Default text color
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const HomeScreen(), // Set the home screen
    );
  }
}