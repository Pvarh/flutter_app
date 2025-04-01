import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:provider/provider.dart';
import '../providers/recept_provider.dart';

class FunctionsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Function to open the Kategoria dialog
  void openKategoriaDialog(BuildContext context, Function nacitatKategorie) {
    String? _novaKategoria;
    String? _errorText;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Použijem dialogContext pre dialóg
        // Použijem StatefulBuilder pre dynamické aktualizácie
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Color.fromRGBO(242, 247, 251, 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text(
                "Pridať kategóriu",
                style: TextStyle(
                  color: Color.fromARGB(255, 43, 40, 40),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    onChanged: (value) async {
                      if (value.trim().isNotEmpty) {
                        //  Získam existujúce kategórie z DB
                        final existingCategories =
                            await _dbHelper.getKategorie();
                        //  Skontrolujem, či už existuje kategória s rovnakým názvom
                        final exists = existingCategories.any(
                          (category) =>
                              category['nazov']?.toLowerCase() ==
                              value.toLowerCase(),
                        );

                        setStateDialog(() {
                          _novaKategoria = value;
                          _errorText = exists ? "Kategória už existuje" : null;
                        });
                      } else {
                        setStateDialog(() {
                          _novaKategoria = null;
                          _errorText = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Názov kategórie',
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 43, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 43, 40, 40),
                        ),
                      ),
                      errorText: _errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      () =>
                          Navigator.pop(dialogContext), // Použiem dialogContext
                  child: const Text(
                    '✖',
                    style: TextStyle(color: Color.fromARGB(255, 90, 29, 29)),
                  ),
                ),
                TextButton(
                  // Podmienka pre povolenie tlačidla zostáva rovnaká
                  onPressed:
                      _novaKategoria != null &&
                              _novaKategoria!.trim().isNotEmpty &&
                              _errorText == null
                          ? () async {
                            // 1. Uložim kategóriu do DB
                            await _dbHelper.insertKategoria(_novaKategoria!);

                            // 2. Načítam kategórie do providera
                            // 2.1 Použijem try-catch blok pre istotu, že provider je dostupný
                            try {
                              final receptProvider =
                                  Provider.of<ReceptProvider>(
                                    context,
                                    listen: false,
                                  );
                              await receptProvider
                                  .nacitatKategorie(); // Načítaj kategórie do providera
                            } catch (e) {
                              print(
                                "Chyba pri načítaní kategórií do providera po pridaní: $e",
                              );
                              // Prípadne zobraziť chybu používateľovi
                            }

                            // 3. Zavolaj pôvodný callback (ak je stále potrebný pre lokálny refresh)
                            nacitatKategorie();

                            // 4. Zavri dialóg
                            Navigator.pop(dialogContext); // Použi dialogContext
                          }
                          : null, // Tlačidlo je neaktívne, ak podmienky nie sú splnené
                  child: const Text(
                    'Pridať',
                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Predpokladaná metóda na získanie kategórií z DB helpera (prispôsob podľa tvojho DatabaseHelper)
  // Toto je len pre funkčnosť validácie v tomto príklade
  // V tvojom kóde už máš _dbHelper.getKategorie(), čo je správne
  /* Future<List<dynamic>> _getAllKategorieForValidation() async {
     // Vráť List<Map<String, dynamic>> alebo inú štruktúru, ktorú vracia tvoj helper
     return await _dbHelper.getKategorie() ?? []; 
  } 
  */
}
