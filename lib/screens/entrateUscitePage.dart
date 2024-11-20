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
  DateTime? _selectedDate; // Data selezionata per il filtro

  @override
  void initState() {
    super.initState();
    _fetchEntrateUscite();
  }

  Future<void> _fetchEntrateUscite() async {
    List<Map<String, dynamic>> entrate = await DatabaseHelper.getEntrate(widget.id);
    List<Map<String, dynamic>> uscite = [];
    for (var entrata in entrate) {
      var uscita = await DatabaseHelper.getUsciteByEntrataId(entrata['id']);
      if (uscita.isNotEmpty) {
        uscite.add(uscita[0]);
      } else {
        uscite.add({});
      }
    }

    List<Map<String, dynamic>> dipendenti = await Dipendente.getDipendentibyId(widget.id);

    setState(() {
      _entrate = entrate;
      _uscite = uscite;
      _dipendenti = dipendenti;
      dipendente = _dipendenti.isNotEmpty ? _dipendenti[0] : null;
    });
  }

  void _editEntrataUscita(Map<String, dynamic> entrata, Map<String, dynamic>? uscita) {
    TextEditingController entrataController = TextEditingController(text: entrata['ora'] ?? '');
    TextEditingController uscitaController = TextEditingController(text: uscita?['ora'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifica Entrata/Uscita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: TextField(
                  controller: entrataController,
                  decoration: InputDecoration(labelText: 'Ora Entrata'),
                ),
              ),
              Flexible(
                child: TextField(
                  controller: uscitaController,
                  decoration: InputDecoration(
                    labelText: uscita == null ? 'Aggiungi Ora Uscita' : 'Modifica Ora Uscita',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper.updateEntrataById(
                  entrata['id'],
                  entrataController.text,
                );

                if (uscita == null || uscitaController.text.isNotEmpty) {
                  if (uscita == null) {
                    await DatabaseHelper.addUscitaByData(
                      entrata['data'],
                      uscitaController.text,
                      entrata['id'],
                    );
                  } else {
                    await DatabaseHelper.updateUscitaByDataOra(
                      uscita['data'],
                      uscita['ora'],
                      uscitaController.text,
                    );
                  }
                }

                _fetchEntrateUscite();
                Navigator.of(context).pop();
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
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 30),  // Aggiungi spazio sui lati
          child: Builder(
            builder: (context) {
              return Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Aggiungi questa proprietà
                      children: [
                        Text(
                          'Sei sicuro di voler eliminare questa entrata e la relativa uscita (se presente)?',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Annulla'),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (entrata != null) {
                                  await DatabaseHelper.deleteEntrataById(entrata['id']);
                                }
                                if (uscita != null) {
                                  await DatabaseHelper.deleteUscitaById(uscita['id']);
                                }

                                _fetchEntrateUscite();
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'Elimina',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

  }

  void _filterByDate(DateTime? date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredEntrate = _selectedDate != null
        ? _entrate.where((entrata) {
      DateTime entrataDate = DateTime.parse("${entrata['data']} ${entrata['ora']}");
      return _selectedDate != null &&
          DateFormat('yyyy-MM-dd').format(entrataDate) == DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }).toList()
        : _entrate;

    return Scaffold(
      appBar: AppBar(
        title: dipendente != null
            ? Text('Entrate/Uscite di ${dipendente['cognome']} ${dipendente['nome']}',style: TextStyle(color: Colors.white))
            : Text('Entrate/Uscite'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today ,  color: Colors.white,),
            onPressed: () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              _filterByDate(selectedDate);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredEntrate.length,
              itemBuilder: (context, index) {
                var entrata = filteredEntrate[index];
                var uscita = _uscite.isNotEmpty && index < _uscite.length ? _uscite[index] : null;

                String entrataDataOra = "${entrata['data']} ${entrata['ora']}";
                DateTime? entrataDateTime = _parseDateTime(entrataDataOra);

                String uscitaDataOra = uscita != null ? "${uscita['data']} ${uscita['ora']}" : '';
                DateTime? uscitaDateTime = _parseDateTime(uscitaDataOra);

                return Card(
                  child: ListTile(
                    title: Text(
                      "Data: ${entrataDateTime != null ? DateFormat('dd-MM-yyyy').format(entrataDateTime) : 'Data non disponibile'}",
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entrataDateTime != null)
                          Text("Entrata: ${DateFormat('HH:mm').format(entrataDateTime)}"),
                        if (uscitaDateTime != null)
                          Text("Uscita: ${DateFormat('HH:mm').format(uscitaDateTime)}"),
                      ],
                    ),
                    onTap: () => _editEntrataUscita(entrata, uscita),
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

  DateTime? _parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
    try {
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      print('Errore nel parsing della data/ora: $e');
      return null;
    }
  }
}
