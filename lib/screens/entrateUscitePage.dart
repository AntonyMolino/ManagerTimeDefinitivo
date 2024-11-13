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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: dipendente != null
            ? Text('Entrate/Uscite di ${dipendente['cognome']} ${dipendente['nome']}')
            : Text('Entrate/Uscite'),
        backgroundColor: Colors.indigo,
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
                DateTime entrataDateTime = DateTime.parse(entrataDataOra);

                String uscitaDataOra = uscita != null ? "${uscita['data']} ${uscita['ora']}" : '';
                DateTime? uscitaDateTime = uscita != null ? DateTime.parse(uscitaDataOra) : null;

                return Card(
                  child: ListTile(
                    title: Text("Data: ${DateFormat('dd-MM-yyyy').format(entrataDateTime)}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Entrata: ${DateFormat('HH:mm').format(entrataDateTime)}"),
                        if (uscitaDateTime != null)
                          Text("Uscita: ${DateFormat('HH:mm').format(uscitaDateTime)}"),
                        if (uscitaDateTime == null)
                          Text("Uscita non registrata", style: TextStyle(color: Colors.red)),
                      ],
                    ),
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
