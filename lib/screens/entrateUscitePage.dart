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

    List<Map<String, dynamic>> entrate = await DatabaseHelper.getEntrate(widget.id);
    List<Map<String, dynamic>> uscite = await DatabaseHelper.getUscite(widget.id);
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
                // Aggiorna l'orario di entrata nel database
                await DatabaseHelper.updateEntrataByDataOra(
                  entrata['data'],
                  entrata['ora'],
                  entrataController.text,
                );

                if (uscita == null) {
                  // Inserisce una nuova uscita se non esiste
                  await DatabaseHelper.addUscitaByData(
                    entrata['data'], // Usa la stessa data dell'entrata
                    uscitaController.text, // Nuovo orario di uscita
                  );
                } else {
                  // Aggiorna l'orario di uscita esistente
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
                DateTime? entrataDateTime = entrata != null ? DateTime.parse(entrataDataOra) : null;

                String uscitaDataOra = uscita != null ? "${uscita['data']} ${uscita['ora']}" : '';
                DateTime? uscitaDateTime = uscita != null ? DateTime.parse(uscitaDataOra) : null;

                return Card(
                  child: ListTile(
                    title: Text("Data: ${DateFormat('dd-MM-yyyy').format(entrataDateTime!)}"),
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
                      _editEntrataUscita(entrata, uscita ); // Gestisce il tocco della card
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
}
