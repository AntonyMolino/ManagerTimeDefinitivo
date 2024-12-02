import 'package:managertime/db/DatabaseHelper.dart';

class Dipendente {
  final int? id;
  final String nome;
  final String cognome;
  final String email;
  final String codiceFiscale;

  Dipendente({
    this.id,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.codiceFiscale,
  });



  // Convertire da Map a oggetto Dipendente
  factory Dipendente.fromMap(Map<String, dynamic> map) {
    return Dipendente(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      cognome: map['cognome'] as String,
      email: map['email'] as String,
      codiceFiscale: map['codiceFiscale'] as String,
    );
  }

  // Convertire da oggetto Dipendente a Map per il database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'codiceFiscale': codiceFiscale,
    };
  }

  /// **Metodi statici per operazioni sui dipendenti**

  // Inserisce un nuovo dipendente nel database
  static Future<void> insertDipendente(
      String nome,
      String cognome,
      String email,
      String codiceFiscale,
      ) async {
    final db = await DatabaseHelper.getDatabase;
    await db.insert('Dipendenti', {
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'codiceFiscale': codiceFiscale,
    });
  }

  static Future<void> updateDipendente(int id, String nome, String cognome, String email, String codiceFiscale) async {
    final db = await DatabaseHelper.getDatabase;

    await db.update(
      'Dipendenti', // Nome della tabella
      {
        'nome': nome,
        'cognome': cognome,
        'email': email,
        'codiceFiscale': codiceFiscale,
      }, // Nuovi valori
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getDipendenti() async {
    final db = await DatabaseHelper.getDatabase;
    return await db.query('Dipendenti');

  }
  
  static Future<List<Map<String, dynamic>>> getDipendentibyId(int id) async {
    final db = await DatabaseHelper.getDatabase;
    return await db.query(
      'Dipendenti',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Elimina un dipendente tramite l'ID
  static Future<void> deleteDipendenteById(int id) async {
    final db = await DatabaseHelper.getDatabase;
    await db.delete(
      'Dipendenti',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  static Future<List<Map<String, dynamic>>> getDipendenteByCodiceFiscale(String codiceFiscale) async {
    // Eseguiamo una query sul database per cercare un dipendente con il codice fiscale specificato
    var db = await DatabaseHelper.getDatabase;
    var result = await db.query(
      'dipendenti', // Nome della tabella che contiene i dipendenti
      where: 'codiceFiscale = ?',
      whereArgs: [codiceFiscale],
    );

    return result;
}
}
