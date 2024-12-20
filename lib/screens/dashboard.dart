import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';



import 'package:managertime/db/FirebaseDipendente.dart';
import 'package:managertime/db/FirebaseDatabaseHelper.dart';
import 'package:managertime/screens/login.dart';

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
        title: Text('Sistema di Registrazione',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false, // Rimuove tutte le schermate precedenti
              );
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
    List<Map<String, dynamic>> dipendenti =
        await Dipendente.getDipendenteByCodiceFiscale(codiceFiscale);
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
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
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

  Future<int> calcolaOreLavorate() async {
    List<Map<String, dynamic>> logs =
        await FirebaseDatabaseHelper.getLogEntrateUscite(codiceFiscale);
    int oreLavorate = 0;

    for (var log in logs) {
      if (log['oraEntrata'] != null &&
          log['oraUscita'] != null &&
          log['data'] != null) {
        DateTime entrata = DateTime.parse('${log['data']}T${log['oraEntrata']}');
        DateTime uscita = DateTime.parse('${log['data']}T${log['oraUscita']}');
        print(entrata);
        print(uscita);

        oreLavorate += uscita.difference(entrata).inHours;
      }
    }

    return oreLavorate;
  }

  Future<Map<String, dynamic>> getDipendente() async {
    List<Map<String, dynamic>> dipendenti =
        await Dipendente.getDipendenteByCodiceFiscale(codiceFiscale);
    return dipendenti.isNotEmpty ? dipendenti[0] : {};
  }

  @override
  Widget build(BuildContext context) {
    final double oreTotali = 8;
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
                      // Codice modificato per mostrare il grafico nel showDialog per l'uscita con successo

                      onPressed: () async {
                        print("Id utente $dipendente['id']");
                        Map<String, dynamic>? ultimaEntrata =
                            await FirebaseDatabaseHelper.getUltimaEntrataAperta(
                                dipendente['id']);
                        if (ultimaEntrata == null) {
                          bool entrataRegistrata =
                              await FirebaseDatabaseHelper.registraEntrata(
                                  dipendente['id']);
                          if (entrataRegistrata) {
                            // Successo nella registrazione dell'entrata
                            final result = await showDialog<bool>(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                double progress = 0.0;

                                // Variabile per gestire il timer
                                Timer? timer;

                                return StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setState) {
                                    // Avvio del timer solo se non è già stato avviato
                                    if (timer == null) {
                                      timer = Timer.periodic(
                                          Duration(milliseconds: 200),
                                          (Timer t) {
                                        if (progress >= 1.0) {
                                          t.cancel();
                                          // Chiude il dialogo e restituisce `true`
                                          if (context.mounted) {
                                            LoginScreen().createState();
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .pop(true);
                                          }
                                        } else {
                                          setState(() {
                                            progress += 0.10;
                                          });
                                        }
                                      });
                                    }

                                    return AlertDialog(
                                      backgroundColor: Colors.green,
                                      title: Text(
                                        'Successo!',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Entrata registrata con successo!',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          SizedBox(height: 20),
                                          LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor:
                                                Colors.white.withOpacity(0.3),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );

                            if (result == true) {
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                                (route) =>
                                    false, // Rimuove tutte le schermate precedenti
                              );
                            }
                          } else {
                            final result = await showDialog<bool>(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                double progress = 0.0;
                                Timer? timer;
                                // StatefulBuilder per aggiornare dinamicamente la UI del dialogo
                                return StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setState) {
                                    // Avvio del timer solo se non è già stato avviato
                                    if (timer == null) {
                                      timer = Timer.periodic(
                                          Duration(milliseconds: 200),
                                          (Timer t) {
                                        if (progress >= 1.0) {
                                          t.cancel();
                                          // Chiude il dialogo e restituisce `true`
                                          if (context.mounted) {
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .pop(true);
                                          }
                                        } else {
                                          setState(() {
                                            progress += 0.10;
                                          });
                                        }
                                      });
                                    }

                                    return AlertDialog(
                                      backgroundColor: Colors
                                          .red, // Colore di sfondo (verde per il successo)
                                      title: Text(
                                        'Errore!',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Entrata non registrata!',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          SizedBox(height: 20),
                                          LinearProgressIndicator(
                                            value:
                                                progress, // Aggiorna dinamicamente il valore
                                            backgroundColor:
                                                Colors.white.withOpacity(0.3),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                            if (result == true) {
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                                (route) =>
                                    false, // Rimuove tutte le schermate precedenti
                              );
                            }
                          }
                        } else {
                          bool uscitaRegistrata =
                              await FirebaseDatabaseHelper.registraUscita(
                                  dipendente['id']);
                          if (uscitaRegistrata) {
                            // Successo nella registrazione dell'uscita, ora mostra il grafico
                            if (!context.mounted) return;
                            final result = await showDialog<bool>(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                double progress = 0.0;
                                Timer? timer;

                                return StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setState) {
                                    // Avvio del timer solo se non è già stato avviato
                                    if (timer == null) {
                                      timer = Timer.periodic(
                                          Duration(milliseconds: 200),
                                          (Timer t) {
                                        if (progress >= 1.0) {
                                          t.cancel();
                                          // Chiude il dialogo e restituisce `true`
                                          if (context.mounted) {
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .pop(true);
                                          }
                                        } else {
                                          setState(() {
                                            progress += 0.10;
                                          });
                                        }
                                      });
                                    }

                                    return AlertDialog(
                                      backgroundColor: Colors
                                          .green, // Colore di sfondo per il successo
                                      title: Text(
                                        'Successo!',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Uscita registrata con successo!',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          SizedBox(height: 20),
                                          FutureBuilder<int>(
                                            future: calcolaOreLavorate(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasError) {
                                                return Text(
                                                    'Errore nel calcolo delle ore.',
                                                    style: TextStyle(
                                                        color: Colors.white));
                                              } else if (snapshot.hasData) {
                                                print("snapshot presente");
                                                int oreLavorate = snapshot.data!;
                                                double percentualeLavorata = (oreLavorate / oreTotali) * 100;
                                                double percentualeNonLavorata = 100 - percentualeLavorata;
                                                print("percentuale lavorata : $percentualeLavorata , percentuale non lavorata $percentualeNonLavorata");
                                                return Column(
                                                  children: [
                                                    Container(
                                                      width: double.infinity,
                                                      height:
                                                          200, // Altezza del diagramma a torta
                                                      child: PieChart(
                                                        PieChartData(
                                                          sections: [
                                                            PieChartSectionData(
                                                              value:
                                                                  percentualeLavorata,
                                                              title:
                                                                  '${percentualeLavorata.toStringAsFixed(1)}%',
                                                              color:
                                                                  Colors.indigo,
                                                              radius: 50,
                                                              titleStyle:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            PieChartSectionData(
                                                              value:
                                                                  percentualeNonLavorata,
                                                              title:
                                                                  '${percentualeNonLavorata.toStringAsFixed(1)}%',
                                                              color: Colors.red,
                                                              radius: 50,
                                                              titleStyle:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          width: 20,
                                                          height: 20,
                                                          color: Colors
                                                              .indigo, // Colore delle ore lavorate
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Ore Lavorate',
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .white)),
                                                        SizedBox(width: 20),
                                                        Container(
                                                          width: 20,
                                                          height: 20,
                                                          color: Colors
                                                              .red, // Colore delle ore non lavorate
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Ore non lavorate',
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .white)),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              } else {
                                                return Text(
                                                    'Nessun dato disponibile.',
                                                    style: TextStyle(
                                                        color: Colors.white));
                                              }
                                            },
                                          ),
                                          SizedBox(height: 20),
                                          LinearProgressIndicator(
                                            value:
                                                progress, // Valore dinamico per il progresso
                                            backgroundColor:
                                                Colors.white.withOpacity(0.3),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                            if (result == true) {
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                                (route) =>
                                    false, // Rimuove tutte le schermate precedenti
                              );
                            }
                          } else {
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                double progress = 0.0;

                                // StatefulBuilder per aggiornare dinamicamente la UI del dialogo
                                return StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setState) {
                                    // Timer per aggiornare il progresso
                                    Timer.periodic(Duration(milliseconds: 300),
                                        (Timer timer) {
                                      if (progress >= 1.0) {
                                        timer
                                            .cancel(); // Ferma il timer una volta completato
                                        Navigator.of(context)
                                            .pop(); // Chiudi il dialogo
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                LoginScreen(), // Naviga alla nuova schermata
                                          ),
                                        );
                                      } else {
                                        setState(() {
                                          progress +=
                                              0.01; // Incrementa il progresso
                                        });
                                      }
                                    });

                                    return AlertDialog(
                                      backgroundColor: Colors
                                          .red, // Colore di sfondo (verde per il successo)
                                      title: Text(
                                        'Errore!',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Uscita non registrata!',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          SizedBox(height: 20),
                                          LinearProgressIndicator(
                                            value:
                                                progress, // Aggiorna dinamicamente il valore
                                            backgroundColor:
                                                Colors.white.withOpacity(0.3),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.login_outlined, color: Colors.white),
                      label: Text('Registra Entrata/Uscita'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class HoursWorkedSection extends StatelessWidget {
  final String codiceFiscale;

  HoursWorkedSection({required this.codiceFiscale});

  Future<String> calcolaOreLavorate() async {
    List<Map<String, dynamic>> logs =
        await FirebaseDatabaseHelper.getLogEntrateUscite(codiceFiscale);
    String stringhe = "";
    int oreTotali = 0;
    int minutiTotali = 0;
    for (var log in logs) {
      if (log['oraEntrata'] != null &&
          log['oraUscita'] != null &&
          log['data'] != null) {
        try {
          DateTime entrata =
              DateTime.parse('${log['data']}T${log['oraEntrata']}');
          DateTime uscita =
              DateTime.parse('${log['data']}T${log['oraUscita']}');

          Duration durata = uscita.difference(entrata);
          oreTotali += durata.inMinutes ~/ 60; // Ore intere
          minutiTotali += durata.inMinutes % 60;

          stringhe = "$oreTotali,$minutiTotali";
        } catch (e) {
          print('Errore nel parsing del log: $log, errore: $e');
        }
      }
    }

    return stringhe;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: calcolaOreLavorate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          String oreLavorate = snapshot.data!;

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
                Center(
                  child: Text(
                    'Ore lavorate totali: $oreLavorate  ore',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          );
        } else {
          return Center(child: Text('Nessun dato disponibile.'));
        }
      },
    );
  }
}

class EntryExitLogsSection extends StatelessWidget {
  final String codiceFiscale;

  EntryExitLogsSection({required this.codiceFiscale});

  Future<List<Map<String, dynamic>>> getLogs() async {
    return await FirebaseDatabaseHelper.getLogEntrateUscite(codiceFiscale);
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
          Center(
            child: Text(
              'Log Entrate/Uscite',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: getLogs(), // La funzione getLogs recupera i log
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
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap:
                        true, // Risolve il problema di overflow con i log
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      var log = logs[index];
                      var data = DateTime.parse(log['data']);
                      var dataDef =
                          DateFormat('dd-MM-yyyy').format(data).toString();
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation:
                            4, // Aggiungi ombra per creare un effetto di profondità
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(dataDef),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mostra orario entrata
                              Text('Entrata: ${log['oraEntrata']}'),
                              // Mostra uscita o messaggio "Non registrata"
                              Text(
                                'Uscita: ${log['oraUscita'] ?? 'Non registrata'}',
                                style: TextStyle(
                                    color: log['oraUscita'] == null
                                        ? Colors.red
                                        : null),
                              ),
                            ],
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Mostra codice fiscale
                              Text('Codice Fiscale: ${log['codiceFiscale']}'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
