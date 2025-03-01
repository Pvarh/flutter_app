import 'package:flutter/material.dart';
import '../database_helper.dart'; // Import your DatabaseHelper

class FunctionsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Function to open the Kategoria dialog
  void openKategoriaDialog(BuildContext context, Function nacitatKategorie) {
    String? _novaKategoria;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Color.fromRGBO(
                242,
                247,
                251,
                1.0,
              ), // Match your widget background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              title: const Text(
                "Pridať kategóriu",
                style: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40), // Dark text color
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: TextFormField(
                onChanged: (value) {
                  setStateDialog(() {
                    _novaKategoria = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Názov kategórie',
                  labelStyle: TextStyle(
                    color: Color.fromARGB(255, 43, 40, 40), // Dark text color
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 43, 40, 40), // Dark border
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '✖',
                    style: TextStyle(
                      color: Color.fromARGB(
                        255,
                        90,
                        29,
                        29,
                      ), // red text for cancel
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _novaKategoria != null &&
                          _novaKategoria!.trim().isNotEmpty
                      ? () async {
                          await _dbHelper.insertKategoria(_novaKategoria!);
                          nacitatKategorie(); // Call the callback to refresh categories
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text(
                    'Pridať',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0), // Black text for add
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add more reusable functions here as needed
}