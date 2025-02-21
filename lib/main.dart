import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/recept_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReceptProvider()),
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
      title: 'Receptár',
      theme: ThemeData(
        
      ).copyWith(
        colorScheme: ThemeData().colorScheme.copyWith(
          primary: const Color.fromARGB(255, 43, 185, 102),
          secondary: const Color.fromARGB(255, 233, 118, 11),
          surface: const Color.fromARGB(255, 128, 198, 142),
          onSurface: const Color.fromARGB(255, 43, 40, 40),
        ),
      ),
      home: const HomeScreen(   
      ),

    );
  }
}
