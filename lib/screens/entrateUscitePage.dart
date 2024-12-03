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
    List<Map<String, dynamic>> entrate =
    await FirebaseDatabaseHelper.getEntrate(widget.id);
    List<Map<String, dynamic>> uscite = [];
    for (var entrata in entrate) {
      var uscita = await FirebaseDatabaseHelper.getUsciteByEntrataId(entrata['id']);
      if (uscita.isNotEmpty) {
        uscite.add(uscita[0]);
      } else {
        uscite.add({});
      }
    }

    List<Map<String, dynamic>> dipendenti =
    await Dipendente.getDipendenteById(widget.id);

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
    TextEditingController entrataController =
    TextEditingController(text: entrata['ora']);
    TextEditingController uscitaController =
    TextEditingController(text: uscita != null ? uscita['ora'] : '');

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
                await FirebaseDatabaseHelper.updateEntrataById(
                  entrata['id'],
                  entrataController.text,
                );
                if (uscita == null) {
                  await FirebaseDatabaseHelper.addUscitaByData(
                    entrata['data'],
                    uscitaController.text,
                    entrata['id'],
                  );
                } else {
                  await FirebaseDatabaseHelper.updateUscitaById(
                    uscita['id'],
                    uscitaController.text,
                  );
                }
                await _fetchEntrateUscite();
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
      builder: (context) {
        return AlertDialog(
          title: Text('Conferma Eliminazione'),
          content: Text(
              'Sei sicuro di voler eliminare questa entrata e la relativa uscita?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseDatabaseHelper.deleteEntrataById(entrata['id']);
                if (uscita != null) {
                  await FirebaseDatabaseHelper.deleteUscitaById(uscita['id']);
                }
                await _fetchEntrateUscite();
                Navigator.of(context).pop();
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
    List<Map<String, dynamic>> filteredEntrate = _entrate.where((entrata) {
      DateTime entrataDate = DateTime.parse("${entrata['data']} ${entrata['ora']}");
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
