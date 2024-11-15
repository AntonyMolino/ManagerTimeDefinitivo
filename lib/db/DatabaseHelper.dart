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
        uscitaId INTEGER,
        FOREIGN KEY(dipendenteEntr) REFERENCES Dipendenti(id),
        FOREIGN KEY(uscitaId) REFERENCES uscite(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE uscite (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dipendenteUsc INTEGER,
        data DATETIME,
        ora DATETIME,
        chiuso INTEGER,
        entrataId INTEGER,
        FOREIGN KEY(dipendenteUsc) REFERENCES Dipendenti(id),
        FOREIGN KEY(entrataId) REFERENCES entrate(id)
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
      final entrataApertaId = await checkEntrataAperta(dipendenteId);

      if (entrataApertaId != null) {
        print('Entrata già aperta per oggi');
        return false;
      }

      final db = await getDatabase;
      var dataOraCorrente = DateTime.now();
      final data = DateFormat("yyyy-MM-dd").format(dataOraCorrente);
      final ora = DateFormat("HH:mm").format(dataOraCorrente);

      // Inserisci una nuova entrata
      final result = await db.insert('entrate', {
        'dipendenteEntr': dipendenteId,
        'data': data,
        'ora': ora,
        'chiuso': 0, // Stato aperto
      });

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
    final ultimaEntrata = await getUltimaEntrata(dipendenteId);

    if (ultimaEntrata != null) {
      final entrataId = ultimaEntrata['id'];

      await db.update(
        'entrate',
        {'chiuso': 1},
        where: 'id = ?',
        whereArgs: [entrataId],
      );
      print("Entrata chiusa con successo.");
    }
  }
  // Funzione per aggiornare l'entrata usando l'ID
  static Future<void> updateEntrataById(int entrataId, String nuovaOra) async {
    final db = await getDatabase;

    // Aggiorna solo l'entrata che ha l'ID specificato
    await db.update(
      'entrate',
      {'ora': nuovaOra}, // Nuovo orario
      where: 'id = ?',
      whereArgs: [entrataId], // Usa l'ID per identificare l'entrata univocamente
    );
  }


  static Future<void> updateEntrataByDataOra(String data, String oraOriginale, String nuovaOra) async {
    final db = await getDatabase;
    await db.update(
      'entrate',
      {'ora': nuovaOra},
      where: 'data = ? AND ora = ?',
      whereArgs: [data, oraOriginale],
    );
  }
  static Future<void> updateUscitaByDataOra(String data, String oraOriginale, String nuovaOra) async {
    final db = await getDatabase;
    await db.update(
      'uscite',
      {'ora': nuovaOra},
      where: 'data = ? AND ora = ?',
      whereArgs: [data, oraOriginale],
    );
  }
  static Future<void> addUscitaByData(String entrataData, String uscitaOra, int entrataId) async {
    final db = await getDatabase;
    await db.insert(
      'uscite',
      {
        'data': entrataData,
        'ora': uscitaOra,
        'entrataId': entrataId,  // Aggiungi l'entrataId
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }



  static Future<bool> registraUscita(int dipendenteId) async {
    // Controlla se esiste un'entrata aperta per il dipendente
    final entrataApertaId = await checkEntrataAperta(dipendenteId);

    if (entrataApertaId == null) {
      // Nessuna entrata aperta, non permette di registrare un'uscita
      return false;
    }

    final db = await getDatabase;
    var dataOraCorrente = DateTime.now();
    final data = DateFormat("yyyy-MM-dd").format(dataOraCorrente);
    final ora = DateFormat("HH:mm").format(dataOraCorrente);

    // Inserisci l'uscita con l'entrataId
    final uscitaId = await db.insert('uscite', {
      'dipendenteUsc': dipendenteId,
      'data': data,
      'ora': ora,
      'chiuso': 1, // Indica che l'uscita è chiusa
      'entrataId': entrataApertaId, // Associa l'uscita all'entrata aperta
    });

    // Ora aggiorna l'entrata per associare l'uscita
    await db.update(
      'entrate',
      {
        'chiuso': 1, // Indica che l'entrata è chiusa
        'uscitaId': uscitaId, // Collega l'uscita appena registrata
      },
      where: 'id = ?',
      whereArgs: [entrataApertaId],
    );

    print("Uscita registrata e collegata all'entrata");
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
  static Future<List<Map<String, dynamic>>> getUsciteByEntrataId(int entrataId) async {
    final db = await getDatabase;
    return await db.query(
      'uscite',
      where: 'entrataId = ?',
      whereArgs: [entrataId],
    );
  }



// Funzione per eliminare un'entrata usando l'ID
  static Future<void> deleteEntrataById(int entrataId) async {
    final db = await getDatabase;

    // Elimina solo l'entrata con l'ID specificato
    await db.delete(
      'entrate',
      where: 'id = ?',
      whereArgs: [entrataId], // Usa l'ID per identificare l'entrata univocamente
    );
  }
  // Funzione per eliminare un'uscita usando l'ID
  static Future<void> deleteUscitaById(int uscitaId) async {
    final db = await getDatabase;

    // Elimina solo l'uscita con l'ID specificato
    await db.delete(
      'uscite',
      where: 'id = ?',
      whereArgs: [uscitaId], // Usa l'ID per identificare l'uscita univocamente
    );
  }





}
