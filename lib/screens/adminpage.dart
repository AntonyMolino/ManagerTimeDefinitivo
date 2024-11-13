import 'package:flutter/material.dart';
import 'package:managertime/db/DatabaseHelper.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> _dipendenti = [];

  @override
  void initState() {
    super.initState();
    _fetchDipendenti();
  }

  Future<void> _fetchDipendenti() async {
    List<Map<String, dynamic>> dipendenti = await DatabaseHelper.getDipendenti();
    setState(() {
      _dipendenti = dipendenti;
    });
  }

  Future<void> _addDipendente(String nome, String cognome, String email, String codiceFiscale) async {
    await DatabaseHelper.insertDipendente(nome, cognome, email, codiceFiscale);
    _fetchDipendenti();
  }

  void _showAddDipendenteDialog() {
    String nome = '';
    String cognome = '';
    String email = '';
    String codiceFiscale = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Aggiungi Dipendente"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: "Nome"),
              onChanged: (value) => nome = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: "Cognome"),
              onChanged: (value) => cognome = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: "Email"),
              onChanged: (value) => email = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: "Codice Fiscale"),
              onChanged: (value) => codiceFiscale = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Annulla"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text("Aggiungi"),
            onPressed: () async {
              await _addDipendente(nome, cognome, email, codiceFiscale);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - Gestione Dipendenti',
        style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: _dipendenti.length,
        itemBuilder: (context, index) {
          var dipendente = _dipendenti[index];
          return ListTile(
            title: Text("${dipendente['nome']} ${dipendente['cognome']}"),
            subtitle: Text("Email: ${dipendente['email']}\nCF: ${dipendente['codiceFiscale']}"),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDipendenteDialog,
        child: Icon(Icons.add,
        color: Colors.white,),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
