import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/recept_provider.dart';
import 'providers/functions_provider.dart';
import 'screens/moje_recepty.dart'; // Import MojeRecepty directly


void main() {
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReceptProvider()), // State management for recipes
        ChangeNotifierProvider(create: (_) => FunctionsProvider()),
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
              primary: const Color.fromARGB(255, 88, 88, 88), // Primary color
              surface: const Color.fromARGB(210, 255, 255, 255), // Surface color
              onSurface: const Color.fromARGB(255, 43, 40, 40), // Text color on surface
            ),
        // Add more theme customizations if needed
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Make AppBar background transparent
          elevation: 0, // Remove shadow
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 100, 100, 100), // AppBar title text color
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const MojeRecepty(), // Set MojeRecepty as the home screen
    );
  }
}