import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreAutoIncrement {
  // Riferimento alla collezione "counters"
  static final CollectionReference _counterCollection =
  FirebaseFirestore.instance.collection('counters');

  // Funzione generica per ottenere il prossimo ID per qualsiasi tipo di contatore
  static Future<int> getNextId(String counterName) async {
    final counterDoc = _counterCollection.doc(counterName);

    try {
      final result = await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterDoc);

        if (!snapshot.exists) {
          // Se il contatore non esiste, inizializzalo a 1
          transaction.set(counterDoc, {'value': 1});
          return 1;
        }

        final currentValue = snapshot.get('value') as int;
        final nextValue = currentValue + 1;

        // Incrementa il contatore nel database
        transaction.update(counterDoc, {'value': nextValue});

        return nextValue;
      });

      return result;
    } catch (e) {
      print('Errore durante il recupero dell\'ID incrementale: $e');
      throw e;
    }
  }
}
