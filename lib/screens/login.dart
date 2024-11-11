import 'package:flutter/material.dart';
import '/screens/dashboard.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  MobileScannerController cameraController = MobileScannerController();

  void _onScan(Barcode barcode, MobileScannerArguments? args) {
    final String scannedData = barcode.rawValue ?? "Unknown";

    if (scannedData == 'yourLoginToken') {
      // Sostituisci 'yourLoginToken' con il token che vuoi usare per il login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // Se il codice QR non è valido
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Codice QR non valido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo.jpg',
            fit: BoxFit.contain,
          ),
        ),
        title: Text('Sistema di Registrazione'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scansiona il codice QR per accedere:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: MobileScanner(
                controller: cameraController,
                onDetect: _onScan, // Funzione chiamata quando un codice viene scansionato
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                cameraController.toggleTorch(); // Per attivare/disattivare la torcia
              },
              child: Text('Accendi/Spegni Torcia'),
            ),
          ],
        ),
      ),
    );
  }
}
