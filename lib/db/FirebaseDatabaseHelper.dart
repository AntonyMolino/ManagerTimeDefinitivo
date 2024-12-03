import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      // Ottieni la data corrente nel formato richiesto
      var  dataCorrente = DateFormat("yyyy-MM-dd").format(DateTime.now()).toString().trim();
      print("check entrata aperta : $dipendenteId");
      print("check entrata aperta : $dataCorrente");
      // Esegui la query su Firestore
      final querySnapshot = await _firestore
          .collection('Entrate')
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .where('data', isEqualTo: dataCorrente) // Filtra per data corrente
          .where('chiuso', isEqualTo: false) // Filtra per le entrate aperte
          .orderBy('ora', descending: true) // Ordina per ora decrescente
          .limit(1) // Prendi solo l'ultima entrata aperta
          .get();

      // Se c'è almeno un documento (entrata aperta trovata)
      if (querySnapshot.docs.isNotEmpty) {
        final entrataId = querySnapshot.docs.first.data()['id'] as int;
        print('Entrata aperta trovata: $entrataId');
        return entrataId; // Restituisci l'ID dell'entrata aperta
      } else {
        print('checkentrata : Nessuna entrata aperta trovata per dipendente ID $dipendenteId');
        return null; // Nessuna entrata aperta trovata
      }
    } catch (e) {
      print('Errore nel metodo checkEntrataAperta: $e');
      return null; // Gestione degli errori
    }
  }


  // Registra un'uscita
  static Future<bool> registraUscita(int dipendenteId) async {
    try {
      // Verifica se esiste un'entrata aperta
      final entrataAperta = await checkEntrataAperta(dipendenteId);
      final int id = await FirestoreAutoIncrement.getNextId('usciteId');
      if (entrataAperta == null) {
        print("Uscita : Nessuna entrata aperta trovata per registrare l'uscita.");
        return false;
      }

      final dataOraCorrente = DateTime.now();
      final entrataId = entrataAperta;
      final String data = DateFormat("yyyy-MM-dd").format(DateTime.now()).toString();
      final ora = "${dataOraCorrente.hour}:${dataOraCorrente.minute}";

      // Registra l'uscita
      final uscitaRef = await _usciteCollection.doc(id.toString()).set({
        'dipendenteUsc': dipendenteId,
        'data': data,
        'ora': ora,
        'entrataId': entrataId,
        'uscitaId' : id,
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
      // Query Firestore per trovare l'ultima entrata aperta
      final querySnapshot = await _firestore
          .collection('Entrate')
          .where('dipendenteEntr', isEqualTo: dipendenteId) // Filtra per dipendente
          .where('uscitaId', isEqualTo: null) // Filtra per entrate senza uscita collegata
          .orderBy('data', descending: true) // Ordina per data in ordine decrescente
          .limit(1) // Prendi solo il primo documento
          .get();

      // Se troviamo un'entrata aperta
      if (querySnapshot.docs.isNotEmpty) {
        final document = querySnapshot.docs.first;
        return {
          'id': document.id, // ID del documento
          ...document.data(), // Dati dell'entrata
        };
      } else {
        print('Nessuna entrata aperta trovata per dipendente ID $dipendenteId');
        return null;
      }
    } catch (e) {
      print('Errore nel metodo getUltimaEntrataAperta: $e');
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
  static Future<bool> updateEntrataById(int entrataId, String update) async {
    try {
      await _entrateCollection.doc(entrataId.toString()).update({
        'data' : update,
      }
      );
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
    return await updateEntrataById(entrataId,  nuovaOra);
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

  static Future<List<Map<String, dynamic>>> getUsciteByEntrataId(int entrataId) async {
    try {
      // Otteniamo i documenti dalla collezione 'uscite' filtrando per 'entrataId'
      final querySnapshot = await _firestore
          .collection('uscite')
          .where('entrataId', isEqualTo: entrataId)
          .get();

      // Convertiamo i documenti ottenuti in una lista di Map
      final uscite = querySnapshot.docs.map((doc) => doc.data()).toList();

      print('Uscite trovate per entrataId $entrataId: $uscite');
      return uscite;
    } catch (e) {
      print('Errore durante il recupero delle uscite per entrataId $entrataId: $e');
      return [];
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

  static Future<List<Map<String, dynamic>>> getEntrate(int dipendenteId) async {
    try {
      final querySnapshot = await _firestore
          .collection('Entrate')
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .orderBy('data', descending: true)
          .get();

      List<Map<String, dynamic>> entrateList = [];
      for (var doc in querySnapshot.docs) {
        entrateList.add(doc.data());
      }

      return entrateList;
    } catch (e) {
      print("Errore durante il recupero delle entrate su Firebase: $e");
      return [];
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
