import 'package:cloud_firestore/cloud_firestore.dart';

class Dipendente {
  final String? id;
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
  factory Dipendente.fromMap(Map<String, dynamic> map, {String? id}) {
    return Dipendente(
      id: id,
      nome: map['nome'] as String,
      cognome: map['cognome'] as String,
      email: map['email'] as String,
      codiceFiscale: map['codiceFiscale'] as String,
    );
  }

  // Convertire da oggetto Dipendente a Map per Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'codiceFiscale': codiceFiscale,
    };
  }

  /// **Metodi statici per Firebase**
  static final CollectionReference _dipendentiCollection =
  FirebaseFirestore.instance.collection('dipendenti');

  // Inserisce un nuovo dipendente
  static Future<void> insertDipendente(
      String nome,
      String cognome,
      String email,
      String codiceFiscale,
      ) async {
    try {
      await _dipendentiCollection.add({
        'nome': nome,
        'cognome': cognome,
        'email': email,
        'codiceFiscale': codiceFiscale,
      });
      print("Dipendente aggiunto con successo!");
    } catch (e) {
      print("Errore nell'aggiunta del dipendente: $e");
    }
  }

  // Aggiorna un dipendente esistente
  static Future<void> updateDipendente(
      String id,
      String nome,
      String cognome,
      String email,
      String codiceFiscale,
      ) async {
    try {
      await _dipendentiCollection.doc(id).update({
        'nome': nome,
        'cognome': cognome,
        'email': email,
        'codiceFiscale': codiceFiscale,
      });
      print("Dipendente aggiornato con successo!");
    } catch (e) {
      print("Errore nell'aggiornamento del dipendente: $e");
    }
  }

  // Recupera tutti i dipendenti
  static Future<List<Dipendente>> getDipendenti() async {
    try {
      final querySnapshot = await _dipendentiCollection.get();
      return querySnapshot.docs
          .map((doc) => Dipendente.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    } catch (e) {
      print("Errore nel recupero dei dipendenti: $e");
      return [];
    }
  }

  // Recupera un dipendente per codice fiscale
  static Future<Dipendente?> getDipendenteByCodiceFiscale(String codiceFiscale) async {
    try {
      final querySnapshot = await _dipendentiCollection
          .where('codiceFiscale', isEqualTo: codiceFiscale)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Dipendente.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
      }
      print("Nessun dipendente trovato con il codice fiscale specificato.");
      return null;
    } catch (e) {
      print("Errore nel recupero del dipendente: $e");
      return null;
    }
  }

  // Recupera un dipendente per ID
  static Future<Dipendente?> getDipendenteById(String id) async {
    try {
      final doc = await _dipendentiCollection.doc(id).get();
      if (doc.exists) {
        return Dipendente.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
      }
      print("Nessun dipendente trovato con l'ID specificato.");
      return null;
    } catch (e) {
      print("Errore nel recupero del dipendente: $e");
      return null;
    }
  }

  // Elimina un dipendente tramite ID
  static Future<void> deleteDipendenteById(String id) async {
    try {
      await _dipendentiCollection.doc(id).delete();
      print("Dipendente eliminato con successo!");
    } catch (e) {
      print("Errore nell'eliminazione del dipendente: $e");
    }
  }
}
