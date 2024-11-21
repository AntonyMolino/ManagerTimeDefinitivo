import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:managertime/db/DatabaseHelper.dart';
import 'package:managertime/db/Dipendente.dart';

class HomePage extends StatelessWidget {
  final String codiceFiscale;

  const HomePage({super.key, required this.codiceFiscale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo.jpg',
            fit: BoxFit.contain,
          ),
        ),
        title: Text('Sistema di Registrazione', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              print('Utente uscito');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sezione di benvenuto
            WelcomeSection(codiceFiscale: codiceFiscale),
            SizedBox(height: 20),

            // Sezione Entrate/Uscite
            EntryExitSection(codiceFiscale: codiceFiscale),
            SizedBox(height: 20),

            // Sezione Ore Lavorate
            HoursWorkedSection(codiceFiscale: codiceFiscale),
            SizedBox(height: 20),

            // Log Entrate/Uscite
            EntryExitLogsSection(codiceFiscale: codiceFiscale),
          ],
        ),
      ),
    );
  }
}

class WelcomeSection extends StatelessWidget {
  final String codiceFiscale;

  const WelcomeSection({super.key, required this.codiceFiscale});

  Future<Map<String, dynamic>> getDipendente() async {
    var dipendente;
    List<Map<String, dynamic>> dipendenti = await Dipendente.getDipendenteByCodiceFiscale(codiceFiscale);
    if (dipendenti.isNotEmpty) {
      dipendente = dipendenti[0];
    }
    return dipendente ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getDipendente(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          var dipendente = snapshot.data!;
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Benvenuto ${dipendente['nome']} ${dipendente['cognome']}",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Buona giornata di lavoro!',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
                Icon(Icons.person, color: Colors.white, size: 40),
              ],
            ),
          );
        } else {
          return Center(child: Text('Nessun dipendente trovato'));
        }
      },
    );
  }
}

class EntryExitSection extends StatelessWidget {
  final String codiceFiscale;

  EntryExitSection({required this.codiceFiscale});

  Future<Map<String, dynamic>> getDipendente() async {
    List<Map<String, dynamic>> dipendenti = await Dipendente.getDipendenteByCodiceFiscale(codiceFiscale);
    return dipendenti.isNotEmpty ? dipendenti[0] : {};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Registrazione Entrata/Uscita',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          SizedBox(height: 10),
          FutureBuilder<Map<String, dynamic>>(
            future: getDipendente(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Errore: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Dipendente non trovato'));
              } else {
                var dipendente = snapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        Map<String, dynamic>? ultimaEntrata = await DatabaseHelper.getUltimaEntrataAperta(dipendente['id']);
                        if (ultimaEntrata == null) {
                          bool entrataRegistrata = await DatabaseHelper.registraEntrata(dipendente['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(entrataRegistrata ? 'Entrata registrata con successo!' : 'Errore nella registrazione dell\'entrata. Contatta un admin!'))
                          );
                        } else {
                          bool uscitaRegistrata = await DatabaseHelper.registraUscita(dipendente['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(uscitaRegistrata ? 'Uscita registrata con successo!' : 'Errore nella registrazione dell\'uscita. Contatta un admin!'))
                          );
                        }
                      },
                      icon: Icon(Icons.login_outlined, color: Colors.white),
                      label: Text('Registra Entrata/Uscita'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              'Ultima registrazione: 8:39 AM', // Orario da aggiornare dinamicamente
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class HoursWorkedSection extends StatelessWidget {
  final String codiceFiscale;

  HoursWorkedSection({required this.codiceFiscale});

  Future<int> calcolaOreLavorate() async {
    List<Map<String, dynamic>> logs = await DatabaseHelper.getLogEntrateUscite(codiceFiscale);
    int oreLavorate = 0;
    for (int i = 0; i < logs.length; i++) {
      if (logs[i]['tipo'] == 'uscita' && i > 0 && logs[i - 1]['tipo'] == 'entrata') {
        DateTime entrata = DateTime.parse(logs[i - 1]['orario']);
        DateTime uscita = DateTime.parse(logs[i]['orario']);
        oreLavorate += uscita.difference(entrata).inHours;
      }
    }
    return oreLavorate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Ore Lavorate',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          SizedBox(height: 10),
          FutureBuilder<int>(
            future: calcolaOreLavorate(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Errore: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                int oreLavorate = snapshot.data!;
                return Center(
                  child: Text(
                    'Ore lavorate totali: $oreLavorate ore',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              } else {
                return Center(child: Text('Nessun dato disponibile.'));
              }
            },
          ),
        ],
      ),
    );
  }
}

class EntryExitLogsSection extends StatelessWidget {
  final String codiceFiscale;

  EntryExitLogsSection({required this.codiceFiscale});

  Future<List<Map<String, dynamic>>> getLogs() async {
    return await DatabaseHelper.getLogEntrateUscite(codiceFiscale);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo della sezione
          Text(
            'Log Entrate/Uscite',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: getLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Errore nel recupero dei log.'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Nessun log trovato.'));
              } else {
                List<Map<String, dynamic>> logs = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,  // Risolve il problema di overflow con i log
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    var log = logs[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text('${log['nome']} ${log['cognome']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Entrata: ${log['oraEntrata']}'),
                            Text('Uscita: ${log['oraUscita']}'),
                          ],
                        ),
                        trailing: Text('Codice Fiscale: ${log['codiceFiscale']}'),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
