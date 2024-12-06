import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/FirebaseDatabaseHelper.dart';
import 'package:managertime/db/FirebaseDipendente.dart';

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
  DateTime? _startDate; // Data inizio filtro
  DateTime? _endDate;   // Data fine filtro

  @override
  void initState() {
    super.initState();
    _fetchEntrateUscite();
  }

  Future<void> _fetchEntrateUscite() async {
    // Recupera tutte le entrate per il dipendente
    List<Map<String, dynamic>> entrate = await FirebaseDatabaseHelper.getEntrate(widget.id);

    // Crea una lista vuota per le uscite
    List<Map<String, dynamic>> uscite = [];

    // Recupera le uscite per ogni entrata, se esistono
    for (var entrata in entrate) {
      var uscita = await FirebaseDatabaseHelper.getUscitaByEntrataId(entrata['id']);
      if (uscita != null) {
        uscite.add(uscita);
        print("Uscita trovata per entrata ${entrata['id']}: $uscita");
      } else {
        uscite.add({});
        print("Nessuna uscita trovata per entrata ${entrata['id']}");
      }
    }

    // Recupera i dettagli del dipendente
    List<Map<String, dynamic>> dipendenti = await Dipendente.getDipendenteById(widget.id);

    // Aggiorna lo stato con i dati recuperati
    setState(() {
      _entrate = entrate;
      _uscite = uscite;
      _dipendenti = dipendenti;
      dipendente = _dipendenti.isNotEmpty ? _dipendenti[0] : null;
    });
  }

  void _filterByDateRange(DateTime? start, DateTime? end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  void _editEntry(Map<String, dynamic> entrata, Map<String, dynamic>? uscita) {
    TextEditingController entrataController = TextEditingController(text: entrata['ora']);
    TextEditingController uscitaController = TextEditingController(text: uscita != null ? uscita['ora'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifica Entrata/Uscita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Ora Entrata'),
                trailing: Icon(Icons.edit),
                onTap: () async {
                  TimeOfDay? selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selectedTime != null) {
                    entrataController.text = selectedTime.format(context);
                  }
                },
              ),
              ListTile(
                title: Text('Ora Uscita'),
                trailing: Icon(Icons.edit),
                onTap: () async {
                  TimeOfDay? selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selectedTime != null) {
                    uscitaController.text = selectedTime.format(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                int entrataId = int.parse(entrata['id'].toString());

                // Aggiorna l'entrata
                await FirebaseDatabaseHelper.updateEntrataById(
                  entrataId,
                  entrataController.text, // Ora entrata aggiornata
                );

                if (uscita != null) {
                  int uscitaId = int.parse(uscita['id'].toString());

                  // Aggiorna l'uscita esistente
                  await FirebaseDatabaseHelper.updateUscitaById(
                    uscitaId,
                    uscitaController.text, // Ora uscita aggiornata
                  );
                }

                // Ricarica i dati
                setState(() {
                  _fetchEntrateUscite();  // Ricarica le entrate e uscite
                });

                Navigator.of(context).pop();  // Chiudi il dialog
              },
              child: Text('Salva'),
            ),
          ],
        );
      },
    );
  }



  void _confirmDelete(Map<String, dynamic> entrata, Map<String, dynamic>? uscita) {
    print(uscita);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Conferma Eliminazione'),
          content: Text('Sei sicuro di voler eliminare questa entrata e la relativa uscita?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseDatabaseHelper.deleteEntrataById(entrata['id']);
                String s = uscita!['id'];
                await FirebaseDatabaseHelper.deleteUscitaById(s);


                // Ricarica i dati dopo l'eliminazione
                setState(() {
                  _fetchEntrateUscite();  // Ricarica le entrate e uscite
                });

                Navigator.of(context).pop();  // Chiudi il dialog
              },
              child: Text('Elimina'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    print("Entrate disponibili: $_entrate");
    print("Uscite disponibili: $_uscite");
    print("Valore _startDate: $_startDate");
    print("Valore _endDate: $_endDate");

    List<Map<String, dynamic>> filteredEntrate = _entrate.where((entrata) {
      // Verifica che 'data' e 'ora' siano presenti
      if (entrata['data'] == null || entrata['ora'] == null) return false;

      DateTime? entrataDate;
      try {
        // Parsing della data e dell'ora
        String data = entrata['data']; // Esempio: "2024-12-01"
        String ora = entrata['ora'];   // Esempio: "14:30"
        DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm");
        entrataDate = dateFormat.parse("$data $ora");
      } catch (e) {
        print("Errore nel parsing della data/ora: $e");
        return false; // Ignora l'elemento se il parsing fallisce
      }

      // Applica i filtri di intervallo
      if (_startDate != null && entrataDate.isBefore(_startDate!)) return false;
      if (_endDate != null && entrataDate.isAfter(_endDate!)) return false;

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: dipendente != null
            ? Text(
          'Entrate/Uscite di ${dipendente['cognome']} ${dipendente['nome']}',
          style: TextStyle(color: Colors.white),
        )
            : Text('Entrate/Uscite'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range, color: Colors.white),
            onPressed: () async {
              DateTimeRange? selectedRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDateRange: _startDate != null && _endDate != null
                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                    : null,
              );
              if (selectedRange != null) {
                _filterByDateRange(selectedRange.start, selectedRange.end);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Periodo: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEntrate.length,
              itemBuilder: (context, index) {
                var entrata = filteredEntrate[index];
                var uscita = _uscite.isNotEmpty && index < _uscite.length
                    ? _uscite[index]
                    : null;

                return Card(
                  child: ListTile(
                    title: Text("Data: ${entrata['data']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Entrata: ${entrata['ora']}"),
                        if (uscita != null && uscita.isNotEmpty)
                          Text("Uscita: ${uscita['ora']}"),
                      ],
                    ),
                    onTap: () => _editEntry(entrata, uscita),
                    onLongPress: () => _confirmDelete(entrata, uscita),
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
