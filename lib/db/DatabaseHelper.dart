import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

   static Future<Database> get getDatabase async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

   static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'company_database.db');
    print(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
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
        ora DATETIME,
        chiuso INTEGER,
        FOREIGN KEY(dipendenteEntr) REFERENCES Dipendenti(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE uscite (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dipendenteUsc INTEGER,
        data DATETIME,
        ora DATETIME,
        chiuso INTEGER,
        FOREIGN KEY(dipendenteUsc) REFERENCES Dipendenti(id)
      )
    ''');
  }
  //INSERT
  static Future<void> insertDipendente(String nome , String cognome , String email, String codiceFiscale) async {
    final db = await getDatabase;
    await db.insert('Dipendenti', {
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'codiceFiscale': codiceFiscale,
      'hash': "",
    });
  }


  static Future<bool> registraEntrata(int dipendenteId) async {
    final entrataAperta = await checkEntrataAperta(dipendenteId);
    final uscitaAperta = await checkUscitaAperta(dipendenteId);

    if (entrataAperta || uscitaAperta) {
      // Non permette di registrare un'entrata se c'è già un'entrata o un'uscita aperta
      return false;
    }

    final db = await getDatabase;
    final dataOraCorrente = DateTime.now();

    // Estrai la data senza l'ora
    final data = DateTime(dataOraCorrente.year, dataOraCorrente.month, dataOraCorrente.day);

    // Estrai e formatta l'ora come "HH:mm"
    final timeFormatted = "${dataOraCorrente.hour.toString().padLeft(2, '0')}:${dataOraCorrente.minute.toString().padLeft(2, '0')}";

    await db.insert('entrate', {
      'dipendenteEntr': dipendenteId,
      'data': data.toIso8601String().substring(0, 10), // Data senza l'ora
      'ora': timeFormatted, // Ora formattata come "HH:mm"
      'chiuso': 0, // Entrata aperta
    });

    return true; // Entrata registrata con successo
  }
  static Future<Map<String, dynamic>?> getUltimaEntrata(int dipendenteId) async {
    final db = await getDatabase;

    // Ottieni la data di oggi (per limitare la ricerca a oggi)
    final oggi = DateTime.now();
    final dataOggi = DateTime(oggi.year, oggi.month, oggi.day);

    // Ottieni l'ultima entrata (ordinata per data e ora decrescente)
    final result = await db.query(
      'entrate',
      where: 'dipendenteEntr = ? AND date(data) = ?',
      whereArgs: [dipendenteId, dataOggi.toIso8601String().substring(0, 10)],
      orderBy: 'data DESC', // Ordina per data decrescente (l'ultima entrata)
      limit: 1, // Solo l'ultima entrata
    );

    // Se trovi un risultato, restituisci il primo
    if (result.isNotEmpty) {
      return result.first;
    }

    return null; // Se non trovi nessuna entrata, restituisci null
  }

  static Future<void> chiudiUltimaEntrata(int dipendenteId) async {
    final db = await getDatabase;

    // Ottieni l'ultima entrata del dipendente
    final ultimaEntrata = await getUltimaEntrata(dipendenteId);

    // Se esiste un'entrata aperta (non chiusa)
    if (ultimaEntrata != null) {
      final entrataId = ultimaEntrata['id']; // Supponendo che l'entrata abbia un campo 'id'

      // Aggiorna lo stato 'chiuso' dell'entrata a 1
      await db.update(
        'entrate',
        {'chiuso': 1}, // Imposta 'chiuso' a 1
        where: 'id = ?',
        whereArgs: [entrataId],
      );
    }
  }


  static Future<bool> registraUscita(int dipendenteId) async {
    final entrataAperta = await checkEntrataAperta(dipendenteId);
    final uscitaAperta = await checkUscitaAperta(dipendenteId);

    if (!entrataAperta || uscitaAperta) {
      // Non permette una nuova uscita se non c'è un'entrata aperta o se c'è già un'uscita aperta
      return false;
    }

    final db = await getDatabase;
    final dataOraCorrente = DateTime.now();

    // Estrai la data senza l'ora
    final data = DateTime(dataOraCorrente.year, dataOraCorrente.month, dataOraCorrente.day);

    // Estrai e formatta l'ora come "HH:mm"
    final timeFormatted = "${dataOraCorrente.hour.toString().padLeft(2, '0')}:${dataOraCorrente.minute.toString().padLeft(2, '0')}";
    chiudiUltimaEntrata(dipendenteId);
    await db.insert('uscite', {
      'dipendenteUsc': dipendenteId,
      'data': data.toIso8601String().substring(0, 10), // Data senza l'ora
      'ora': timeFormatted, // Ora formattata come "HH:mm"
      'chiuso': 1, // Uscita chiusa
    });

    return true; // Uscita registrata con successo
  }


  //UPDATE
  static Future<void> updateEntrataTime(int id, String ora) async {
    final db = await getDatabase;
    await db.update(
      'entrate',
      {'ora': ora},
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  static Future<void> updateUscitaTime(int id, String ora) async {
    final db = await getDatabase;
    await db.update(
      'uscite',
      {'ora': ora},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  static Future<bool> checkEntrataAperta(int dipendenteId) async {
    final db = await getDatabase;

    // Ottieni la data di oggi (senza ora)
    final oggi = DateTime.now();
    final dataOggi = DateTime(oggi.year, oggi.month, oggi.day);

    // Query per cercare un'entrata non chiusa
    final result = await db.query(
      'entrate',
      where: 'dipendenteEntr = ? AND data = ? AND chiuso = ?',
      whereArgs: [dipendenteId, dataOggi.toIso8601String().substring(0, 10), 0],
    );

    return result.isNotEmpty; // Restituisce true se c'è un'entrata aperta
  }

  static Future<bool> checkUscitaAperta(int dipendenteId) async {
    final db = await getDatabase;

    // Ottieni la data di oggi (senza ora)
    final oggi = DateTime.now();
    final dataOggi = DateTime(oggi.year, oggi.month, oggi.day);

    // Query per cercare un'uscita non chiusa
    final result = await db.query(
      'uscite',
      where: 'dipendenteUsc = ? AND data = ? AND chiuso = ?',
      whereArgs: [dipendenteId, dataOggi.toIso8601String().substring(0, 10), 0],
    );

    return result.isNotEmpty; // Restituisce true se c'è un'uscita aperta
  }


  //GET
  static Future<List<Map<String, dynamic>>> getDipendenti() async {
    final db = await getDatabase;
    return await db.query('Dipendenti');

  }
  static Future<List<Map<String, dynamic>>> getDipendentibyCodiceFiscale(String codiceFiscale) async {
    final db = await getDatabase;
    return await db.query(
      'Dipendenti',
      where: 'codiceFiscale = ?',
      whereArgs: [codiceFiscale],
    );
  }

  static Future<List<Map<String, dynamic>>> getDipendentibyId(int id) async {
    final db = await getDatabase;
    return await db.query(
      'Dipendenti',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getEntrate(int dipendenteId) async {
    final db = await getDatabase;
    return await db.query(
      'entrate',
      where: 'dipendenteEntr = ?',
      whereArgs: [dipendenteId],
    );
  }

  static Future<List<Map<String, dynamic>>> getUscite(int dipendenteId) async {
    final db = await getDatabase;
    return await db.query(
      'uscite',
      where: 'dipendenteUsc = ?',
      whereArgs: [dipendenteId],
    );
  }





}
