import 'package:flutter/material.dart';
import 'package:managertime/db/Dipendente.dart';
import 'package:managertime/screens/entrateUscitePage.dart';
import '';

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
    List<Map<String, dynamic>> dipendenti = await Dipendente.getDipendenti();
    setState(() {
      _dipendenti = dipendenti;
    });
  }

  Future<void> _addDipendente(String nome, String cognome, String email, String codiceFiscale) async {
    await Dipendente.insertDipendente(nome, cognome, email, codiceFiscale);
    _fetchDipendenti();
  }

  void _showAddDipendenteDialog() {
    String nome = '';
    String cognome = '';
    String email = '';
    String codiceFiscale = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifica Dati'),
          content: SingleChildScrollView( // Aggiunge il supporto per lo scrolling
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Il Column prenderà solo lo spazio necessario
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: "Nome"),
                    onChanged: (value) => nome = value,
                  ),
                  SizedBox(height: 8.0), // Distanza tra i campi
                  TextField(
                    decoration: InputDecoration(labelText: "Cognome"),
                    onChanged: (value) => cognome = value,
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    decoration: InputDecoration(labelText: "Email"),
                    onChanged: (value) => email = value,
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    decoration: InputDecoration(labelText: "Codice Fiscale"),
                    onChanged: (value) => codiceFiscale = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Chiude il dialogo
              },
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                // Logica per salvare i dati
                Navigator.of(context).pop(); // Chiude il dialogo dopo aver salvato
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Admin - Gestione Dipendenti',
        style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _dipendenti.length,
        itemBuilder: (context, index) {
          var dipendente = _dipendenti[index];
          // Se il nome o il cognome è "admin", salta questo elemento
          if (dipendente['nome'] == "admin" || dipendente['cognome'] == "admin") {
            return SizedBox.shrink(); // Ritorna un widget vuoto
          }
          return ListTile(
            title: Text("${dipendente['nome']} ${dipendente['cognome']}"),
            subtitle: Text("Email: ${dipendente['email']}\nCF: ${dipendente['codiceFiscale']}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EntrateUscitePage(
                    id: dipendente['id'],
                  ),
                ),
              );
            },
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
