import 'package:cloud_firestore/cloud_firestore.dart';

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
  static Future<bool> registraEntrata(String dipendenteId) async {
    try {
      // Verifica se esiste un'entrata aperta
      final entrataAperta = await checkEntrataAperta(dipendenteId);

      if (entrataAperta != null) {
        print("Entrata già aperta per oggi.");
        return false;
      }

      final dataOraCorrente = DateTime.now();
      final data = "${dataOraCorrente.year}-${dataOraCorrente.month}-${dataOraCorrente.day}";
      final ora = "${dataOraCorrente.hour}:${dataOraCorrente.minute}";

      // Inserisci una nuova entrata
      await _entrateCollection.add({
        'dipendenteEntr': dipendenteId,
        'data': data,
        'ora': ora,
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
  static Future<DocumentSnapshot?> checkEntrataAperta(String dipendenteId) async {
    try {
      final dataCorrente = DateTime.now();
      final data = "${dataCorrente.year}-${dataCorrente.month}-${dataCorrente.day}";

      // Query per trovare un'entrata non chiusa
      final querySnapshot = await _entrateCollection
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .where('data', isEqualTo: data)
          .where('chiuso', isEqualTo: false)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      print("Errore durante la verifica dell'entrata aperta: $e");
      return null;
    }
  }

  // Registra un'uscita
  static Future<bool> registraUscita(String dipendenteId) async {
    try {
      // Verifica se esiste un'entrata aperta
      final entrataAperta = await checkEntrataAperta(dipendenteId);

      if (entrataAperta == null) {
        print("Nessuna entrata aperta trovata per registrare l'uscita.");
        return false;
      }

      final entrataId = entrataAperta.id;
      final dataOraCorrente = DateTime.now();
      final data = "${dataOraCorrente.year}-${dataOraCorrente.month}-${dataOraCorrente.day}";
      final ora = "${dataOraCorrente.hour}:${dataOraCorrente.minute}";

      // Registra l'uscita
      final uscitaRef = await _usciteCollection.add({
        'dipendenteUsc': dipendenteId,
        'data': data,
        'ora': ora,
        'entrataId': entrataId,
      });

      // Aggiorna lo stato dell'entrata per chiuderla
      await _entrateCollection.doc(entrataId).update({
        'chiuso': true,
        'uscitaId': uscitaRef.id,
      });

      print("Uscita registrata con successo.");
      return true;
    } catch (e) {
      print("Errore durante la registrazione dell'uscita: $e");
      return false;
    }
  }

  // Recupera l'ultima entrata per un dipendente
  static Future<Map<String, dynamic>?> getUltimaEntrata(String dipendenteId) async {
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

  static Future<Map<String, dynamic>?> getUltimaEntrataAperta(String dipendenteId) async {
    try {
      // Otteniamo tutte le entrate del dipendente ordinate per data decrescente
      final querySnapshot = await _firestore
          .collection('entrate')
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .where('chiuso', isEqualTo: 0) // Entrata non chiusa
          .orderBy('data', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Restituiamo l'ultima entrata aperta come una mappa
        return querySnapshot.docs.first.data();
      } else {
        print("Nessuna entrata aperta trovata per il dipendente con ID $dipendenteId.");
        return null;
      }
    } catch (e) {
      print("Errore nel recuperare l'ultima entrata aperta: $e");
      return null;
    }
  }

  // Recupera i log di entrate/uscite per un dipendente
  static Future<List<Map<String, dynamic>>> getLogEntrateUscite(
      String dipendenteId) async {
    try {
      final querySnapshot = await _entrateCollection
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .orderBy('data', descending: true)
          .get();

      final logs = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final uscitaId = doc['uscitaId'];
        Map<String, dynamic>? uscita;

        if (uscitaId != null) {
          final uscitaSnapshot = await _usciteCollection.doc(uscitaId).get();
          uscita = uscitaSnapshot.data() as Map<String, dynamic>?;
        }

        logs.add({
          'entrata': doc.data(),
          'uscita': uscita,
        });
      }

      return logs;
    } catch (e) {
      print("Errore durante il recupero dei log: $e");
      return [];
    }
  }
  static Future<bool> updateEntrataById(String entrataId, Map<String, dynamic> updates) async {
    try {
      await _entrateCollection.doc(entrataId).update(updates);
      print("Entrata aggiornata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'aggiornamento dell'entrata: $e");
      return false;
    }
  }
  static Future<bool> updateEntrataByDataOra(String dipendenteId, String data, String ora, Map<String, dynamic> updates) async {
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
  static Future<bool> updateEntrataTime(String entrataId, String nuovaOra) async {
    return await updateEntrataById(entrataId, {'ora': nuovaOra});
  }
  static Future<void> updateUscitaById(String uscitaId, String nuovaOra) async {
    try {
      await _firestore.collection('uscite').doc(uscitaId).update({
        'ora': nuovaOra,
      });
      print("Ora dell'uscita aggiornata con successo!");
    } catch (e) {
      print("Errore nell'aggiornare l'ora dell'uscita: $e");
    }
  }

  static Future<bool> updateUscitaTime(String uscitaId, String nuovaOra) async {
    try {
      await _usciteCollection.doc(uscitaId).update({'ora': nuovaOra});
      print("Uscita aggiornata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'aggiornamento dell'uscita: $e");
      return false;
    }
  }
  static Future<DocumentSnapshot?> checkUscitaAperta(String dipendenteId) async {
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
  static Future<List<Map<String, dynamic>>> getUscite(String dipendenteId) async {
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
  static Future<Map<String, dynamic>?> getUsciteByEntrataId(String entrataId) async {
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
  static Future<bool> addUscitaByData(String dipendenteId, String data, String ora) async {
    try {
      final entrataAperta = await checkEntrataAperta(dipendenteId);

      if (entrataAperta == null) {
        print("Nessuna entrata aperta trovata per aggiungere l'uscita.");
        return false;
      }

      final entrataId = entrataAperta.id;
      await _usciteCollection.add({
        'dipendenteUsc': dipendenteId,
        'data': data,
        'ora': ora,
        'entrataId': entrataId,
      });

      await _entrateCollection.doc(entrataId).update({'chiuso': true});
      print("Uscita aggiunta con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'aggiunta dell'uscita: $e");
      return false;
    }
  }
  static Future<bool> deleteEntrataById(String entrataId) async {
    try {
      await _entrateCollection.doc(entrataId).delete();
      print("Entrata eliminata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'eliminazione dell'entrata: $e");
      return false;
    }
  }
  static Future<bool> deleteUscitaById(String uscitaId) async {
    try {
      await _usciteCollection.doc(uscitaId).delete();
      print("Uscita eliminata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'eliminazione dell'uscita: $e");
      return false;
    }
  }
  static Future<List<Map<String, dynamic>>> getEntryExitLogs(String dipendenteId) async {
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
