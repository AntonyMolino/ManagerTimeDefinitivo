import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'company_database.db');
    print(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Dipendenti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        cognome TEXT,
        email TEXT,
        codiceFiscale TEXT,
        hash TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE entrate (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dipendenteEntr INTEGER,
        data DATETIME,
        FOREIGN KEY(dipendenteEntr) REFERENCES Dipendenti(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE uscite (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dipendenteUsc INTEGER,
        data DATETIME,
        FOREIGN KEY(dipendenteUsc) REFERENCES Dipendenti(id)
      )
    ''');
  }
  //INSERT
  Future<void> insertDipendente(Map<String, dynamic> dipendente) async {
    final db = await database;
    await db.insert('Dipendenti', dipendente);
  }

  Future<void> insertEntrata(int dipendenteId) async {
    final db = await database;
    await db.insert('entrate', {
      'dipendenteEntr': dipendenteId,
      'data': DateTime.now().toString(),
    });
  }

  Future<void> insertUscita(int dipendenteId) async {
    final db = await database;
    await db.insert('uscite', {
      'dipendenteUsc': dipendenteId,
      'data': DateTime.now().toString(),
    });
  }
  //GET
  Future<List<Map<String, dynamic>>> getDipendenti() async {
    final db = await database;
    return await db.query('Dipendenti');

  }
  Future<List<Map<String, dynamic>>> getDipendentibyCodiceFiscale(String codiceFiscale) async {
    final db = await database;
    return await db.query(
      'Dipendenti',
      where: 'codiceFiscale = ?',
      whereArgs: [codiceFiscale],
    );
  }

  Future<List<Map<String, dynamic>>> getEntrate(int dipendenteId) async {
    final db = await database;
    return await db.query(
      'entrate',
      where: 'dipendenteEntr = ?',
      whereArgs: [dipendenteId],
    );
  }

  Future<List<Map<String, dynamic>>> getUscite(int dipendenteId) async {
    final db = await database;
    return await db.query(
      'uscite',
      where: 'dipendenteUsc = ?',
      whereArgs: [dipendenteId],
    );
  }


}
