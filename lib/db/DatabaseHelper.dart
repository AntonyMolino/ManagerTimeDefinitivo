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
    String path = join(await getDatabasesPath(), 'app_database.db');
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



    // Ottieni l'ultima entrata (ordinata per data e ora decrescente)
    final result = await db.query(
      'entrate',
      where: 'dipendenteEntr = ? ',
      whereArgs: [dipendenteId],
      orderBy: 'data DESC', // Ordina per data decrescente (l'ultima entrata)
      limit: 1, // Solo l'ultima entrata
    );
    // Se trovi un risultato, restituisci il primo
    if (result.isNotEmpty) {
      return result.first;
    }

    return null; // Se non trovi nessuna entrata, restituisci null
  }
  static Future<Map<String, dynamic>?> getUltimaEntrataAperta(int dipendenteId) async {
    final db = await getDatabase;
     final result = await db.rawQuery('''
    SELECT entrate.id, entrate.dipendenteEntr, entrate.data
    FROM entrate 
    LEFT JOIN uscite  ON entrate.uscitaId = uscite.entrataId
    WHERE entrate.dipendenteEntr = ? AND uscite.id IS NULL
    ORDER BY entrate.data DESC
    LIMIT 1
  ''', [dipendenteId]);

    return result.isNotEmpty ? result.first : null;
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

  static Future<List<Map<String, dynamic>>> getEntryExitLogs(int dipendenteId) async {
    final db = await getDatabase;

    // Recupera i log di entrata/uscita per un dipendente
    final result = await db.rawQuery('''
      SELECT entrate.data, entrate.ora, uscite.data as uscita_data, uscite.ora as uscita_ora, entrate.chiuso
      FROM entrate 
      LEFT JOIN uscite  ON e.id = uscite.entrataId
      WHERE entrate.dipendenteEntr = ?
      ORDER BY entrate.data DESC, entrate.ora DESC
    ''', [dipendenteId]);

    return result;
  }

  static Future<List<Map<String, dynamic>>> getLogEntrateUscite(String codiceFiscale) async {
    final db = await getDatabase;
    List<Map<String, dynamic>> dipendente = await db.query(
        'dipendenti',
        columns: ['id'],
        where: 'codiceFiscale = ?',
        whereArgs: [codiceFiscale]
    );

    if (dipendente.isEmpty) {
      // Se non viene trovato il dipendente con il codice fiscale, restituisci un elenco vuoto
      return [];
    }
    int idDipendente = dipendente.first['id'];  // Ottieni l'id del dipendente
    var now = DateTime.now();
    final data = DateFormat("yyyy-MM-dd").format(now);
    // Query con JOIN tra la tabella entrate, uscite e dipendenti
    return await db.rawQuery('''
        SELECT 
        entrate.id ,
        entrate.dipendenteEntr,
        entrate.ora as oraEntrata,
        entrate.data as data,
        uscite.id as uscita_id,
        uscite.ora as oraUscita,
        Dipendenti.codiceFiscale,
        Dipendenti.nome,
        Dipendenti.cognome
      FROM entrate 
      LEFT JOIN uscite  ON entrate.uscitaId = uscite.id
      INNER JOIN dipendenti ON entrate.dipendenteEntr = Dipendenti.id
      WHERE entrate.dipendenteEntr = ? AND entrate.data = ?
      ORDER BY oraEntrata ASC
    ''', [idDipendente , data]);
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
  static Future<void> updateUscitaById(int uscitaId, String nuovaOra) async {
    final db = await getDatabase;
    await db.update(
      'uscite',
      {'ora': nuovaOra},
      where: 'id = ?',
      whereArgs: [uscitaId],
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
    try {
      // Controlla se esiste un'entrata aperta
      final entrataApertaId = await checkEntrataAperta(dipendenteId);
      if (entrataApertaId == null) {
        print("Errore nella registrazione dell'uscita: nessuna entrata aperta trovata.");
        return false;
      }

      print("Entrata aperta trovata: ID $entrataApertaId");

      final db = await getDatabase;
      final dataOraCorrente = DateTime.now();
      final data = DateFormat("yyyy-MM-dd").format(dataOraCorrente);
      final ora = DateFormat("HH:mm").format(dataOraCorrente);

      // Inserisci l'uscita
      final uscitaId = await db.insert('uscite', {
        'dipendenteUsc': dipendenteId,
        'data': data,
        'ora': ora,
        'chiuso': 1,
        'entrataId': entrataApertaId,
      });

      if (uscitaId > 0) {
        print("Uscita registrata con ID $uscitaId");

        // Aggiorna l'entrata associata
        await db.update(
          'entrate',
          {
            'chiuso': 1,
            'uscitaId': uscitaId,
          },
          where: 'id = ?',
          whereArgs: [entrataApertaId],
        );

        print("Entrata aggiornata con l'uscita ID $uscitaId.");
        return true;
      } else {
        print("Errore durante l'inserimento dell'uscita.");
        return false;
      }
    } catch (e) {
      print('Errore in registraUscita: $e');
      return false;
    }
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
  static Future<int?> checkEntrataAperta(int dipendenteId) async {
    try {
      final db = await getDatabase;

      final data = DateFormat("yyyy-MM-dd").format(DateTime.now());
      final result = await db.query(
        'entrate',
        where: 'dipendenteEntr = ? AND data = ? AND chiuso = ?',
        whereArgs: [dipendenteId, data, 0],
        orderBy: 'id DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        print('Entrata aperta trovata: ${result.first}');
        return result.first['id'] as int;
      } else {
        print('Nessuna entrata aperta trovata per dipendente ID $dipendenteId');
        return null;
      }
    } catch (e) {
      print('Errore nel metodo checkEntrataAperta: $e');
      return null;
    }
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
