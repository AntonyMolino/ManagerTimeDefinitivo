import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:managertime/db/DatabaseHelper.dart';

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
            WelcomeSection(codiceFiscale: codiceFiscale),
            SizedBox(height: 20),
            EntryExitSection(codiceFiscale: codiceFiscale),
            SizedBox(height: 20),
            HoursWorkedSection(),
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
    List<Map<String, dynamic>> dipendenti = await DatabaseHelper.getDipendenti();
    for (var record in dipendenti) {
      if (record['codiceFiscale'] == codiceFiscale) {
        dipendente = record;
        break;
      }
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
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (snapshot.hasData) {
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
        }
        return SizedBox.shrink();
      },
    );
  }
}

class EntryExitSection extends StatelessWidget {
  final String codiceFiscale;

  EntryExitSection({required this.codiceFiscale});

  Future<Map<String, dynamic>> getDipendente() async {
    var dipendente;
    List<Map<String, dynamic>> dipendenti = await DatabaseHelper.getDipendenti();
    for (var record in dipendenti) {
      if (record['codiceFiscale'] == codiceFiscale) {
        dipendente = record;
        break;
      }
    }
    return dipendente ?? {}; // Restituisci un oggetto vuoto se non trovato
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
          Text(
            'Registrazione Entrata/Uscita',
            style: Theme.of(context).textTheme.headlineSmall,
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool alreadyRegistered = await DatabaseHelper.checkEntrata(dipendente['id']);
                        if (alreadyRegistered) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Entrata già registrata per oggi')),
                          );
                        } else {
                          await DatabaseHelper.insertEntrata(dipendente['id']);
                          print("Entrata registrata per ${dipendente['codiceFiscale']}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Entrata registrata con successo!')),
                          );
                        }
                      },
                      icon: Icon(Icons.login, color: Colors.white),
                      label: Text('Entrata'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool alreadyRegistered = await DatabaseHelper.checkUscita(dipendente['id']);
                        if (alreadyRegistered) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Uscita già registrata per oggi')),
                          );
                        } else {
                          await DatabaseHelper.insertUscita(dipendente['id']);
                          print("Uscita registrata per ${dipendente['codiceFiscale']}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Uscita registrata con successo!')),
                          );
                        }
                      },
                      icon: Icon(Icons.logout, color: Colors.white),
                      label: Text('Uscita'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 10),
          // Ultima registrazione orario (data fittizia per il demo)
          Text(
            'Ultima registrazione: 8:39 AM',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class HoursWorkedSection extends StatelessWidget {
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
          Text(
            'Ore di Servizio',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.indigo,
                      value: 75,
                      title: '75%',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.grey[300]!,
                      value: 25,
                      title: '25%',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              'Totale ore: 6 su 8 ore di servizio',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}