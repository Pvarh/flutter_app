import 'package:flutter/material.dart';
import 'moje_recepty.dart';
import 'pridat_recept.dart';

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
      
      body: _widgetOptions[_selectedIndex],backgroundColor: Color.fromARGB(236, 255, 255, 255),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Moje recepty'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Pridať recept'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 161, 244, 144),backgroundColor: Color.fromARGB(228, 0, 0, 0),
        onTap: _onItemTapped,
      ),
    );
  }
}
