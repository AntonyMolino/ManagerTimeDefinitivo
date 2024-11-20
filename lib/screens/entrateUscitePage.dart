import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:managertime/db/Dipendente.dart';
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
      var uscita = await DatabaseHelper.getUsciteByEntrataId(entrata['id']);
      if (uscita.isNotEmpty) {
        uscite.add(uscita[0]);
      } else {
        uscite.add({});
      }
    }

    // Recupera i dipendenti
    List<Map<String, dynamic>> dipendenti = await Dipendente.getDipendentibyId(widget.id);

    setState(() {
      _entrate = entrate;
      _uscite = uscite;
      _dipendenti = dipendenti;
      dipendente = _dipendenti.isNotEmpty ? _dipendenti[0] : null;
    });
  }

  void _editEntrataUscita(Map<String, dynamic> entrata, Map<String, dynamic>? uscita) {
    // Assicurati che i valori non siano nulli e sostituisci con una stringa vuota se lo sono
    String entrataOra = entrata['ora'] ?? ''; // Se 'ora' è null, usa una stringa vuota
    String uscitaOra = uscita?['ora'] ?? ''; // Se 'ora' è null, usa una stringa vuota

    // Inizializza i controller con valori sicuri
    TextEditingController entrataController = TextEditingController(text: entrataOra);
    TextEditingController uscitaController = TextEditingController(text: uscitaOra);

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
                  entrata['id'],
                  entrataController.text.isEmpty ? '' : entrataController.text, // Ora di entrata
                );

                if (uscita == null || uscitaController.text.isNotEmpty) {
                  // Inserisce una nuova uscita se non esiste o se l'utente ha inserito un orario
                  if (uscita == null) {
                    await DatabaseHelper.addUscitaByData(
                      entrata['data'],
                      uscitaController.text.isEmpty ? '' : uscitaController.text, // Ora di uscita
                      entrata['id'],
                    );
                  } else {
                    await DatabaseHelper.updateUscitaByDataOra(
                      uscita['data'],
                      uscita['ora'],
                      uscitaController.text.isEmpty ? '' : uscitaController.text, // Ora di uscita aggiornata
                    );
                  }
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
              if(entrata != null){
                  await DatabaseHelper.deleteEntrataById(entrata['id']);
                }
                if (uscita != null) {
                  await DatabaseHelper.deleteUscitaById(uscita['id']);
                }

                _fetchEntrateUscite();
                Navigator.of(context).pop();
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
  // Funzione per tentare di fare il parse della data, restituendo null in caso di errore
  DateTime? _parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      // Se la stringa è null o vuota, non tentare di fare il parse
      return null;
    }

    try {
      // Se la stringa non è vuota, tentiamo di fare il parse
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      // Se c'è un errore nel parsing, restituire null
      print('Errore nel parsing della data/ora: $e');
      return null;
    }
  }

}
