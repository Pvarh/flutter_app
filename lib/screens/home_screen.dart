import 'package:flutter/material.dart';
import 'moje_recepty.dart';
import 'pridat_recept.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    MojeRecepty(),
    const PridatRecept(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          _widgetOptions[_selectedIndex],

          // Bottom Navigation Bar with Background Image and Blur
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), // Rounded top edges
                topRight: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Adjust blur intensity
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/assets/images/11.png'), // Replace with your image path
                      fit: BoxFit.cover, // Cover the bottom navigation bar area
                    ),
                    color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
                  ),
                  child: BottomNavigationBar(
                    items: const [
                      BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Moje recepty'),
                      BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Pridať recept'),
                    ],
                    currentIndex: _selectedIndex,
                    selectedItemColor: const Color.fromARGB(255, 161, 244, 144),
                    backgroundColor: Colors.transparent, // Make the background transparent
                    elevation: 0, // Remove shadow
                    onTap: _onItemTapped,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
