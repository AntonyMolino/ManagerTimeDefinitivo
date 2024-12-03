import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'FirestoreAutoIncrement.dart';

class FirebaseDatabaseHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collezioni nel database Firebase
  static final CollectionReference _dipendentiCollection =
  _firestore.collection('Dipendenti');
  static final CollectionReference _entrateCollection =
  _firestore.collection('Entrate');
  static final CollectionReference _usciteCollection =
  _firestore.collection('Uscite');

  // Registra una nuova entrata
  static Future<bool> registraEntrata(int dipendenteId) async {
    try {
      // Verifica se esiste un'entrata aperta
      final entrataAperta = await checkEntrataAperta(dipendenteId);
      final int id = await FirestoreAutoIncrement.getNextId('entrateId');
      if (entrataAperta != null) {
        print("Entrata già aperta per oggi.");
        return false;
      }
      final dataOraCorrente = DateTime.now();
      final String data = DateFormat("yyyy-MM-dd").format(DateTime.now()).toString();
      final ora = "${dataOraCorrente.hour}:${dataOraCorrente.minute}";


      // Inserisci una nuova entrata

      await _entrateCollection.doc(id.toString()).set({
        'id' : id,
        'dipendenteEntr': dipendenteId,
        'data': data,
        'ora': ora,
        'uscitaId' : null,
        'chiuso': false, // Stato aperto
      });

      print("Entrata registrata con successo.");
      return true;
    } catch (e) {
      print("Errore durante la registrazione dell'entrata: $e");
      return false;
    }
  }

  // Controlla se esiste un'entrata aperta
  static Future<int?> checkEntrataAperta(int dipendenteId) async {
    try {
      // Formatta la data corrente in formato "yyyy-MM-dd"
      final String data = DateFormat("yyyy-MM-dd").format(DateTime.now()).toString();
      print(data);
      print("l id in check è $dipendenteId");
      // Ottieni la collezione 'entrate' e filtra per dipendenteId, data e chiuso = 0
      final querySnapshot = await _firestore
          .collection('entrate')
          .where('dipendenteEntr', isEqualTo: dipendenteId) // Filtra per ID dipendente
          .where('data', isEqualTo: data) // Filtra per data odierna
          .where('chiuso', isEqualTo: 0) // Filtra per le entrate non chiuse
          .orderBy('data', descending: true) // Ordina per data in ordine decrescente
          .limit(1) // Limita il risultato a una sola entrata
          .get();

      // Controlla se ci sono risultati
      if (querySnapshot.docs.isNotEmpty) {
        // Prendi l'ID dell'entrata
        final entrataId = querySnapshot.docs.first.id;
        print('Entrata aperta trovata: $entrataId');
        return int.tryParse(entrataId); // Restituisce l'ID come numero
      } else {
        print('Nessuna entrata aperta trovata per dipendente ID $dipendenteId');
        return null;
      }
    } catch (e) {
      print('Errore nel metodo checkEntrataAperta: $e');
      return null;
    }
  }

  // Registra un'uscita
  static Future<bool> registraUscita(int dipendenteId) async {
    try {
      // Verifica se esiste un'entrata aperta
      final entrataAperta = await checkEntrataAperta(dipendenteId);
      final int id = await FirestoreAutoIncrement.getNextId('usciteId');
      if (entrataAperta == null) {
        print("Nessuna entrata aperta trovata per registrare l'uscita.");
        return false;
      }

      final entrataId = entrataAperta;
      final dataOraCorrente = DateTime.now();
      final data = "${dataOraCorrente.year}-${dataOraCorrente.month}-${dataOraCorrente.day}";
      final ora = "${dataOraCorrente.hour}:${dataOraCorrente.minute}";

      // Registra l'uscita
      final uscitaRef = await _usciteCollection.doc(id.toString()).set({
        'dipendenteUsc': dipendenteId,
        'data': data,
        'ora': ora,
        'entrataId': entrataId,
      });

      // Aggiorna lo stato dell'entrata per chiuderla
      await _entrateCollection.doc(entrataId.toString()).update({
        'chiuso': true,
        'uscitaId': id,
      });

      print("Uscita registrata con successo.");
      return true;
    } catch (e) {
      print("Errore durante la registrazione dell'uscita: $e");
      return false;
    }
  }

  // Recupera l'ultima entrata per un dipendente
  static Future<Map<String, dynamic>?> getUltimaEntrata(int dipendenteId) async {
    try {
      final querySnapshot = await _entrateCollection
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .orderBy('data', descending: true)
          .orderBy('ora', descending: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.data() as Map<String, dynamic> : null;
    } catch (e) {
      print("Errore durante il recupero dell'ultima entrata: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUltimaEntrataAperta(int dipendenteId) async {
    try {
      // Ottieni tutte le entrate per il dipendente specificato
      print(dipendenteId);
      final entrateSnapshot = await _firestore
          .collection('entrate')
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .where('uscitaId', isEqualTo: null) // Filtra per le entrate che non hanno uscita
          .orderBy('data', descending: true)
          .limit(1) // Prendi solo l'ultima entrata
          .get();

      // Controllo del risultato della query
      if (entrateSnapshot.docs.isNotEmpty) {
        print("Entrata aperta trovata");
        return entrateSnapshot.docs.first.data(); // Restituisci i dati dell'entrata
      } else {
        print("Nessuna entrata aperta trovata");
        return null; // Nessuna entrata aperta trovata
      }
    } catch (e) {
      print("Errore durante il recupero dell'ultima entrata aperta: $e");
      return null; // In caso di errore
    }
  }

  // Recupera i log di entrate/uscite per un dipendente
  static Future<List<Map<String, dynamic>>> getLogEntrateUscite(
      String codiceFiscale) async {
    try {
      // Recupero le entrate del dipendente in base al codice fiscale
      final querySnapshot = await _entrateCollection
          .where('codiceFiscale', isEqualTo: codiceFiscale)  // Filtra per codice fiscale
          .orderBy('data', descending: true)
          .get();

      final logs = <Map<String, dynamic>>[];

      // Itera sui documenti delle entrate recuperati
      for (final doc in querySnapshot.docs) {
        final uscitaId = doc['uscitaId'];  // Recupera l'uscitaId associato all'entrata
        Map<String, dynamic>? uscita;

        // Se esiste un uscitaId, recupera il documento delle uscite
        if (uscitaId != null) {
          final uscitaSnapshot = await _usciteCollection.doc(uscitaId).get();

          if (uscitaSnapshot.exists) {
            uscita = uscitaSnapshot.data() as Map<String, dynamic>?;
          }
        }

        // Aggiungi al log le informazioni dell'entrata e della sua uscita corrispondente
        logs.add({
          'entrata': doc.data(),
          'uscita': uscita ?? {},  // Usa un oggetto vuoto se l'uscita è null
        });
      }

      return logs;  // Ritorna il log
    } catch (e) {
      print("Errore durante il recupero dei log: $e");
      return [];  // In caso di errore, ritorna una lista vuota
    }
  }
  static Future<bool> updateEntrataById(int entrataId, Map<String, dynamic> updates) async {
    try {
      await _entrateCollection.doc(entrataId.toString()).update(updates);
      print("Entrata aggiornata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'aggiornamento dell'entrata: $e");
      return false;
    }
  }
  static Future<bool> updateEntrataByDataOra(int dipendenteId, String data, String ora, Map<String, dynamic> updates) async {
    try {
      final querySnapshot = await _entrateCollection
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .where('data', isEqualTo: data)
          .where('ora', isEqualTo: ora)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Nessuna entrata trovata per data e ora.");
        return false;
      }

      final entrataId = querySnapshot.docs.first.id;
      await _entrateCollection.doc(entrataId).update(updates);
      print("Entrata aggiornata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'aggiornamento dell'entrata per data e ora: $e");
      return false;
    }
  }
  static Future<bool> updateEntrataTime(int entrataId, String nuovaOra) async {
    return await updateEntrataById(entrataId, {'ora': nuovaOra});
  }
  static Future<void> updateUscitaById(int uscitaId, String nuovaOra) async {
    try {
      await _firestore.collection('uscite').doc(uscitaId.toString()).update({
        'ora': nuovaOra,
      });
      print("Ora dell'uscita aggiornata con successo!");
    } catch (e) {
      print("Errore nell'aggiornare l'ora dell'uscita: $e");
    }
  }

  static Future<bool> updateUscitaTime(int uscitaId, String nuovaOra) async {
    try {
      await _usciteCollection.doc(uscitaId.toString()).update({'ora': nuovaOra});
      print("Uscita aggiornata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'aggiornamento dell'uscita: $e");
      return false;
    }
  }
  static Future<DocumentSnapshot?> checkUscitaAperta(int dipendenteId) async {
    try {
      final querySnapshot = await _usciteCollection
          .where('dipendenteUsc', isEqualTo: dipendenteId)
          .where('ora', isNull: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      print("Errore durante il controllo delle uscite aperte: $e");
      return null;
    }
  }
  static Future<List<Map<String, dynamic>>> getUscite(int dipendenteId) async {
    try {
      final querySnapshot = await _usciteCollection
          .where('dipendenteUsc', isEqualTo: dipendenteId)
          .orderBy('data', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Errore durante il recupero delle uscite: $e");
      return [];
    }
  }
  static Future<Map<String, dynamic>?> getUsciteByEntrataId(int entrataId) async {
    try {
      final querySnapshot = await _usciteCollection
          .where('entrataId', isEqualTo: entrataId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.data() as Map<String, dynamic> : null;
    } catch (e) {
      print("Errore durante il recupero dell'uscita per ID entrata: $e");
      return null;
    }
  }
  static Future<bool> addUscitaByData(int dipendenteId, String data, String ora) async {
    try {
      final entrataAperta = await checkEntrataAperta(dipendenteId);

      if (entrataAperta == null) {
        print("Nessuna entrata aperta trovata per aggiungere l'uscita.");
        return false;
      }

      final entrataId = entrataAperta;
      await _usciteCollection.add({
        'dipendenteUsc': dipendenteId,
        'data': data,
        'ora': ora,
        'entrataId': entrataId,
      });

      await _entrateCollection.doc(entrataId.toString()).update({'chiuso': true});
      print("Uscita aggiunta con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'aggiunta dell'uscita: $e");
      return false;
    }
  }
  static Future<bool> deleteEntrataById(int entrataId) async {
    try {
      await _entrateCollection.doc(entrataId.toString()).delete();
      print("Entrata eliminata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'eliminazione dell'entrata: $e");
      return false;
    }
  }
  static Future<bool> deleteUscitaById(int uscitaId) async {
    try {
      await _usciteCollection.doc(uscitaId.toString()).delete();
      print("Uscita eliminata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'eliminazione dell'uscita: $e");
      return false;
    }
  }
  static Future<List<Map<String, dynamic>>> getEntryExitLogs(int dipendenteId) async {
    try {
      final entrateSnapshot = await _entrateCollection
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .orderBy('data', descending: true)
          .get();

      final logs = <Map<String, dynamic>>[];

      for (final entrata in entrateSnapshot.docs) {
        final uscitaId = entrata['uscitaId'];
        Map<String, dynamic>? uscitaData;

        if (uscitaId != null) {
          final uscitaDoc = await _usciteCollection.doc(uscitaId).get();
          uscitaData = uscitaDoc.exists ? uscitaDoc.data() as Map<String, dynamic> : null;
        }

        logs.add({
          'entrata': entrata.data(),
          'uscita': uscitaData,
        });
      }

      return logs;
    } catch (e) {
      print("Errore durante il recupero dei log dettagliati: $e");
      return [];
    }
  }

}
