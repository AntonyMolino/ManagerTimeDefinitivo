import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/DatabaseHelper.dart';

class EntrateUscitePage extends StatefulWidget {
  final int id;

  EntrateUscitePage({required this.id});

  @override
  _EntrateUscitePageState createState() => _EntrateUscitePageState();
}

class _EntrateUscitePageState extends State<EntrateUscitePage> {
  List<Map<String, dynamic>> _entrate = [];
  List<Map<String, dynamic>> _uscite = [];
  List<Map<String, dynamic>> _dipendenti = [];
  var dipendente;

  @override
  void initState() {
    super.initState();
    _fetchEntrateUscite();
  }

  Future<void> _fetchEntrateUscite() async {
    // Recupera le entrate dal database
    List<Map<String, dynamic>> entrate = await DatabaseHelper.getEntrate(widget.id);

    // Recupera le uscite per ogni entrata, usando l'entrataId
    List<Map<String, dynamic>> uscite = [];
    for (var entrata in entrate) {
      var uscita = await DatabaseHelper.getUsciteByEntrataId(entrata['id']); // Passa l'entrataId
      if (uscita.isNotEmpty) {
        uscite.add(uscita[0]); // Aggiungi la prima uscita trovata (assumiamo che ci sia una sola uscita per entrata)
      } else {
        uscite.add({});
      }
    }

    // Recupera i dipendenti (se necessario)
    List<Map<String, dynamic>> dipendenti = await DatabaseHelper.getDipendentibyId(widget.id);

    setState(() {
      _entrate = entrate;
      _uscite = uscite;
      _dipendenti = dipendenti;
      dipendente = _dipendenti.isNotEmpty ? _dipendenti[0] : null;
    });
  }

  void _editEntrataUscita(Map<String, dynamic> entrata, Map<String, dynamic>? uscita) {
    TextEditingController entrataController = TextEditingController(text: entrata['ora']);
    TextEditingController uscitaController = TextEditingController(text: uscita?['ora'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifica Entrata/Uscita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: entrataController,
                decoration: InputDecoration(labelText: 'Ora Entrata'),
              ),
              TextField(
                controller: uscitaController,
                decoration: InputDecoration(
                  labelText: uscita == null ? 'Aggiungi Ora Uscita' : 'Modifica Ora Uscita',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Chiude il dialog
              },
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                // Aggiorna l'orario di entrata nel database usando l'ID
                await DatabaseHelper.updateEntrataById(
                  entrata['id'], // Usa l'ID dell'entrata
                  entrataController.text, // Nuovo orario di entrata
                );

                if (uscita == null) {
                  // Inserisce una nuova uscita se non esiste, associandola all'entrataId
                  await DatabaseHelper.addUscitaByData(
                    entrata['data'], // Usa la stessa data dell'entrata
                    uscitaController.text, // Nuovo orario di uscita
                    entrata['id'], // Passa l'entrataId
                  );
                } else {
                  // Aggiorna l'orario di uscita esistente, associando l'entrataId
                  await DatabaseHelper.updateUscitaByDataOra(
                    uscita['data'],
                    uscita['ora'],
                    uscitaController.text,
                  );
                }

                // Aggiorna la UI
                _fetchEntrateUscite();
                Navigator.of(context).pop(); // Chiude il dialog
              },
              child: Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> entrata, Map<String, dynamic>? uscita) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Conferma Eliminazione'),
          content: Text('Sei sicuro di voler eliminare questa entrata e la relativa uscita (se presente)?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Chiude il dialog senza fare nulla
              },
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                // Elimina l'entrata usando l'ID
                await DatabaseHelper.deleteEntrataById(entrata['id']);

                // Elimina l'uscita usando l'ID, se esiste
                if (uscita != null) {
                  await DatabaseHelper.deleteUscitaById(uscita['id']);
                }

                // Aggiorna la UI
                _fetchEntrateUscite();
                Navigator.of(context).pop(); // Chiude il dialog
              },
              child: Text('Elimina', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: dipendente != null
            ? Text('Entrate/Uscite di ${dipendente['cognome']} ${dipendente['nome']}',
          style: TextStyle(color: Colors.white),)
            : Text('Entrate/Uscite'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _entrate.length,
              itemBuilder: (context, index) {
                var entrata = _entrate[index];
                var uscita = _uscite.isNotEmpty && index < _uscite.length ? _uscite[index] : null;

                String entrataDataOra = "${entrata['data']} ${entrata['ora']}";
                DateTime? entrataDateTime = _parseDateTime(entrataDataOra);

                String uscitaDataOra = uscita != null ? "${uscita['data']} ${uscita['ora']}" : '';
                DateTime? uscitaDateTime = _parseDateTime(uscitaDataOra);

                return Card(
                  child: ListTile(
                    title: Text("Data: ${entrataDateTime != null ? DateFormat('dd-MM-yyyy').format(entrataDateTime) : 'Data non disponibile'}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entrataDateTime != null)
                          Text("Entrata: ${DateFormat('HH:mm').format(entrataDateTime)}"),
                        if (entrataDateTime == null)
                          Text("Entrata non registrata", style: TextStyle(color: Colors.red)),
                        if (uscitaDateTime != null)
                          Text("Uscita: ${DateFormat('HH:mm').format(uscitaDateTime)}"),
                        if (uscitaDateTime == null)
                          Text("Uscita non registrata", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    onTap: () {
                      _editEntrataUscita(entrata, uscita);
                    },
                    onLongPress: () {
                      _confirmDelete(entrata, uscita);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Funzione per tentare di fare il parse della data, restituendo null in caso di errore
  DateTime? _parseDateTime(String dateTimeStr) {
    try {
      return dateTimeStr.isNotEmpty ? DateTime.parse(dateTimeStr) : null;
    } catch (e) {
      print('Errore nel parsing della data/ora: $e');
      return null;
    }
  }
}
