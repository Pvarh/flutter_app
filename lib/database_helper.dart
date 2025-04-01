import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class Kategoria {
  final int id;
  final String nazov;

  Kategoria({required this.id, required this.nazov});

  factory Kategoria.fromMap(Map<String, dynamic> map) {
    return Kategoria(
      id: map['id'],
      nazov: map['nazov'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recepty.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Increment the version number
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade callback for migrations
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recepty (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nazov TEXT NOT NULL,
        kategoria TEXT,
        ingrediencie TEXT,
        postup TEXT,
        poznamky TEXT,
        obrazky TEXT,
        vytvorene TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        isFavorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE kategorie (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nazov TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the isFavorite column to the recepty table
      await db.execute('ALTER TABLE recepty ADD COLUMN isFavorite INTEGER DEFAULT 0');
    }
  }

  // Insert a new recipe
  Future<int> insertRecept(Map<String, dynamic> recept) async {
    final db = await database;
    return await db.insert('recepty', recept);
  }

  // Metóda na získanie všetkých receptov
  Future<List<Map<String, dynamic>>> getRecepty() async {
    final db = await database;
    return await db.query('recepty');
  }

  // Metóda na pridanie kategórie
  Future<int> insertKategoria(String nazov) async {
    final db = await database;
    return await db.insert('kategorie', {'nazov': nazov});
  }

  // Metóda na získanie všetkých kategórií
  Future<List<Map<String, dynamic>>> getKategorie() async {
    final db = await database;
    return await db.query('kategorie');
  }

  // Metóda na odstránenie kategórie podľa ID
  Future<int> deleteKategoria(String nazov) async {
    final db = await database;
    return await db.delete('kategorie', where: 'nazov = ?', whereArgs: [nazov]);
  }

  // Metóda na odstránenie receptu podľa ID
  Future<int> deleteRecept(int id) async {
    final db = await database;
    return await db.delete('recepty', where: 'id = ?', whereArgs: [id]);
  }

  // Metóda na aktualizáciu receptu
  Future<int> updateRecept(Map<String, dynamic> recept) async {
    final db = await database;
    return await db.update(
      'recepty',
      recept,
      where: 'id = ?',
      whereArgs: [recept['id']],
    );
  }

  // Metóda na získanie receptu podľa ID
  Future<Map<String, dynamic>?> getReceptById(int id) async {
    final db = await database;
    final result = await db.query('recepty', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  // Metóda na získanie kategórie podľa ID
  Future<Map<String, dynamic>?> getKategoriaById(int id) async {
    final db = await database;
    final result = await db.query('kategorie', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  // Metóda na získanie všetkých receptov v konkrétnej kategórii
  Future<List<Map<String, dynamic>>> getReceptyByKategoria(String kategoria) async {
    final db = await database;
    return await db.query('recepty', where: 'kategoria = ?', whereArgs: [kategoria]);
  }


  // Metóda na získanie všetkých kategórií
  Future<List<Kategoria>> getAllKategorie() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query('kategorie');
  return List.generate(maps.length, (i) {
    return Kategoria.fromMap(maps[i]);
  });
}
}