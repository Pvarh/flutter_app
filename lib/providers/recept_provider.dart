import 'package:flutter/material.dart';
import '../database_helper.dart';

class ReceptProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _recepty = [];
  List<Map<String, dynamic>> get recepty => _recepty;

  List<String> _kategorie = [];
  List<String> get kategorie => _kategorie;

  // Načítanie receptov z databázy
  Future<void> nacitatRecepty() async {
    _recepty = await _dbHelper.getRecepty();
    notifyListeners();
  }

  // Načítanie kategórií z databázy
  Future<void> nacitatKategorie() async {
    final kategorie = await _dbHelper.getKategorie();
    _kategorie = kategorie.map((k) => k['nazov'] as String).toList();
    notifyListeners();
  }

  // Pridanie nového receptu
  Future<void> pridatRecept(Map<String, dynamic> recept) async {
    await _dbHelper.insertRecept(recept);
    await nacitatRecepty();
  }

  // Aktualizácia existujúceho receptu
  Future<void> updateRecept(Map<String, dynamic> recept) async {
    await _dbHelper.updateRecept(recept);
    await nacitatRecepty();
  }

  // Vymazanie receptu
  Future<void> vymazatRecept(int id) async {
    await _dbHelper.deleteRecept(id);
    await nacitatRecepty();
  }

  // Pridanie novej kategórie
  Future<void> pridatKategoriu(String nazov) async {
    await _dbHelper.insertKategoria(nazov);
    await nacitatKategorie();
  }

  // Vymazanie kategórie
  Future<void> vymazatKategoriu(String nazov) async {
    await _dbHelper.deleteKategoria(nazov);
    await nacitatKategorie();
    await nacitatRecepty();
  }

  // Toggle favorite status of a recipe
  Future<void> toggleFavorite(int id) async {
    // Find the recipe by ID
    final recipeIndex = _recepty.indexWhere((recept) => recept['id'] == id);
    if (recipeIndex != -1) {
      // Create a new mutable copy of the recipe
      final updatedRecept = Map<String, dynamic>.from(_recepty[recipeIndex]);

      // Toggle the isFavorite status
      updatedRecept['isFavorite'] = updatedRecept['isFavorite'] == 1 ? 0 : 1;

      // Update the database
      await _dbHelper.updateRecept(updatedRecept);

      // Create a new mutable list and update the recipe
      final updatedRecepty = List<Map<String, dynamic>>.from(_recepty);
      updatedRecepty[recipeIndex] = updatedRecept;

      // Update the local list of recipes
      _recepty = updatedRecepty;

      // Notify listeners to refresh the UI
      notifyListeners();
    }
  }
}
