import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:managertime/db/FirebaseDipendente.dart';

import 'FirestoreAutoIncrement.dart';

class FirebaseDatabaseHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collezioni nel database Firebase
  static final CollectionReference _dipendentiCollection =
  _firestore.collection('dipendenti');
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
          .where('uscitaId', isNull: true) // Filtra per entrate senza uscita collegata
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
  static Future<List<Map<String, dynamic>>> getLogEntrateUscite(String codiceFiscale) async {
    try {
      // Recupera il dipendente tramite il codice fiscale
      var dipendenteQuery = await FirebaseFirestore.instance
          .collection('dipendenti')
          .where('codiceFiscale', isEqualTo: codiceFiscale)
          .get();

      if (dipendenteQuery.docs.isEmpty) {
        print("Nessun dipendente trovato con il codice fiscale: $codiceFiscale");
        return [];  // Se non troviamo il dipendente, ritorna una lista vuota
      } else {
        var dipendenteDoc = dipendenteQuery.docs.first;
        int dipendenteId = dipendenteDoc['id'];
        print("Dipendente trovato: ${dipendenteDoc['nome']} ${dipendenteDoc['cognome']}");

        var now = DateTime.now();
        String currentYear = DateFormat('yyyy').format(now);
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
        String startOfWeekFormatted = DateFormat('yyyy-MM-dd').format(startOfWeek);
        String endOfWeekFormatted = DateFormat('yyyy-MM-dd').format(endOfWeek);

        // Aggiungi log per vedere le date di inizio e fine settimana
        print("Inizio settimana: $startOfWeekFormatted, Fine settimana: $endOfWeekFormatted");

        // Recupera le entrate per il dipendente
        var entrateQuery = await FirebaseFirestore.instance
            .collection('Entrate')
            .where('dipendenteEntr', isEqualTo: dipendenteId)
            .where('data', isGreaterThanOrEqualTo: startOfWeekFormatted)
            .where('data', isLessThanOrEqualTo: endOfWeekFormatted)
            .orderBy('data')
            .get();

        if (entrateQuery.docs.isEmpty) {
          print("Nessuna entrata trovata per il dipendente nell'intervallo di settimana.");
        } else {
          print("Entrate trovate: ${entrateQuery.docs.length}");
        }

        List<Map<String, dynamic>> logEntrateUscite = [];

        // Recupera le uscite per ogni entrata
        for (var entrataDoc in entrateQuery.docs) {
            // Accesso all'id del documento
            String entrataId = entrataDoc.id;

            // Stampa per debugging
            print("Analizzando entrata con ID: $entrataId");
            print("ID Entrata: ${entrataDoc.id}, Tipo: ${entrataDoc.id.runtimeType}");
            // Query per le uscite basata sull'entrataId
            var uscitaQuery = await FirebaseFirestore.instance
                .collection('Uscite')
                .where('entrataId', isEqualTo: int.parse(entrataDoc.id))
                .get();



            if (uscitaQuery.docs.isNotEmpty) {
              var uscitaDoc = uscitaQuery.docs.first;
              print("Uscita trovata: ${uscitaDoc.data()}");

              // Aggiunta al log
              logEntrateUscite.add({
                'id': entrataId, // Usa entrataId per rappresentare l'ID dell'entrata
                'dipendenteEntr': entrataDoc['dipendenteEntr'],
                'oraEntrata': entrataDoc['ora'],
                'data': entrataDoc['data'].toString(),
                'uscitaId': uscitaDoc.id, // Usa uscitaDoc.id per ottenere l'ID dell'uscita
                'oraUscita': uscitaDoc['ora'],
                'codiceFiscale': dipendenteDoc['codiceFiscale'],
                'nome': dipendenteDoc['nome'],
                'cognome': dipendenteDoc['cognome'],
              });
            } else {
              print("Nessuna uscita trovata per l'entrata con ID: $entrataId");
            }

        }

        // Verifica se i log sono stati recuperati correttamente
        print("Log entrate/uscite recuperati: ${logEntrateUscite.length}");
        print(logEntrateUscite);
        return logEntrateUscite;
      }
    } catch (e) {
      print("Errore durante il recupero dei log: $e");
      return [];
    }
  }

  static Future<bool> updateEntrataById(int entrataId, String update) async {
    try {
      await _entrateCollection.doc(entrataId.toString()).update({
        'ora' : update,
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
      await _firestore.collection('Uscite').doc(uscitaId.toString()).update({
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

  static Future<Map<String, dynamic>?> getUscitaByEntrataId(int entrataId) async {
    if (entrataId <= 0) {
      print("ID entrata non valido.");
      return null;
    }
    try {
      final querySnapshot = await _firestore
          .collection('Uscite')
          .where('entrataId', isEqualTo: entrataId)
          .limit(1) // Limitiamo a una sola uscita
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {
          'id': doc.id, // Include l'ID del documento
          ...doc.data(), // Include i dati
        };
      } else {
        print("Nessuna uscita trovata per entrataId $entrataId.");
        return null;
      }
    } catch (e) {
      print('Errore durante il recupero delle uscite: $e');
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
    String s = entrataId.toString();
    try {
      await _entrateCollection.doc(s).delete();
      print("Entrata eliminata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'eliminazione dell'entrata: $e");
      return false;
    }
  }
  static Future<bool> deleteUscitaById(int uscitaId) async {
    String s = uscitaId.toString();
    try {
      await _usciteCollection.doc(s).delete();
      print("Uscita eliminata con successo.");
      return true;
    } catch (e) {
      print("Errore durante l'eliminazione dell'uscita: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getEntrate(int dipendenteId) async {
    if (dipendenteId <= 0) {
      print("ID dipendente non valido.");
      return [];
    }
    try {
      final querySnapshot = await _firestore
          .collection('Entrate')
          .where('dipendenteEntr', isEqualTo: dipendenteId)
          .orderBy('data', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => {
        'id': doc.id, // Include anche l'ID del documento
        ...doc.data(), // Include i dati
      }).toList();
    } catch (e) {
      print("Errore durante il recupero delle entrate: $e");
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
