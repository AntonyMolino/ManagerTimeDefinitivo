import 'package:intl/intl.dart';
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
    await db.insert('Dipendenti', {
      'nome': "admin",
      'cognome': "admin",
      'email': "",
      'codiceFiscale': "admin",
      'hash': "",
    });
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
    try {
      // Controlla se esiste un'entrata aperta (restituisce l'ID se esiste, altrimenti null)
      final entrataApertaId = await checkEntrataAperta(dipendenteId);

      if (entrataApertaId != null) {
        // Se esiste un'entrata aperta, impedisce la registrazione di una nuova entrata
        print('Entrata già aperta per oggi');
        return false;
      }

      final db = await getDatabase;
      var dataOraCorrente = DateTime.now();
      final data = DateFormat("yyyy-MM-dd").format(dataOraCorrente);
      final ora = DateFormat("HH:mm").format(dataOraCorrente);

      // Inserisce una nuova entrata
      final result = await db.insert('entrate', {
        'dipendenteEntr': dipendenteId,
        'data': data,  // Solo la data
        'ora': ora,    // Solo l'ora
        'chiuso': 0,   // Stato aperto
      });

      // Stampa il risultato dell'inserimento
      print("Dati inseriti, ID dell'entrata: $result");

      return true; // Entrata registrata con successo
    } catch (e) {
      print("Errore durante l'inserimento: $e");
      return false; // Restituisce false in caso di errore
    }
  }

  static Future<Map<String, dynamic>?> getUltimaEntrata(int dipendenteId) async {
    final db = await getDatabase;

    // Ottieni la data di oggi (per limitare la ricerca a oggi)
    var  dataOraCorrente = DateTime.now();
    final data = DateFormat("yyyy-MM-dd").format(dataOraCorrente);



    // Ottieni l'ultima entrata (ordinata per data e ora decrescente)
    final result = await db.query(
      'entrate',
      where: 'dipendenteEntr = ? AND data = ?',
      whereArgs: [dipendenteId , data],
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
    // Controlla se esiste un'entrata aperta
    final entrataApertaId = await checkEntrataAperta(dipendenteId);

    if (entrataApertaId == null) {
      // Nessuna entrata aperta, non permette di registrare un'uscita
      return false;
    }

    final db = await getDatabase;
    var dataOraCorrente = DateTime.now();
    final data = DateFormat("yyyy-MM-dd").format(dataOraCorrente);
    final ora = DateFormat("HH:mm").format(dataOraCorrente);

    // Chiude l'entrata aperta
    await db.update(
      'entrate',
      {'chiuso': 1},
      where: 'id = ?',
      whereArgs: [entrataApertaId],
    );

    // Registra l'uscita
    await db.insert('uscite', {
      'dipendenteUsc': dipendenteId,
      'data': data,
      'ora': ora,
      'chiuso': 1, // Indica l'uscita come chiusa
    });
    print("ho inserito veramente uscita $dipendenteId");
    return true;
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
  static Future<Object?> checkEntrataAperta(int dipendenteId) async {
    final db = await getDatabase;

    var dataOraCorrente = DateTime.now();
    final data = DateFormat("yyyy-MM-dd").format(dataOraCorrente); // Data senza l'ora

    // Controlla se esiste un'entrata aperta per il dipendente nella stessa giornata
    final result = await db.query(
      'entrate',
      where: 'dipendenteEntr = ? AND data = ? AND chiuso = ?',
      whereArgs: [dipendenteId, data, 0], // chiuso = 0 significa aperto
    );

    if (result.isNotEmpty) {
      // Se c'è un'entrata aperta, restituisce l'ID dell'entrata aperta
      return result.first['id']; // Assumendo che 'id' sia la colonna dell'ID dell'entrata
    }

    return null; // Se non ci sono entrate aperte, restituisce null
  }





  static Future<bool> checkUscitaAperta(int dipendenteId) async {
    final db = await getDatabase;

    // Ottieni la data di oggi (senza ora)
    var dataOraCorrente = DateTime.now();
    final data = DateFormat("yyyy-MM-dd").format(dataOraCorrente);

    // Query per cercare un'uscita non chiusa
    final result = await db.query(
      'uscite',
      where: 'dipendenteUsc = ? AND data = ? AND chiuso = ?',
      whereArgs: [dipendenteId, data, 0],
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
