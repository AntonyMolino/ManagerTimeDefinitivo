import 'package:flutter/material.dart';
import 'package:managertime/db/DatabaseHelper.dart';
import 'package:managertime/screens/dashboard.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  MobileScannerController cameraController = MobileScannerController();
  bool _isCameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      cameraController.start();
    }
  }

  void _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isCameraPermissionGranted = true;
      });
    } else if (status.isPermanentlyDenied) {
      _openAppSettings();
    }
  }

  void _openAppSettings() async {
    await openAppSettings();
  }

  Future<void> _onScan(BarcodeCapture barcodeCapture) async {
    final String scannedData = barcodeCapture.barcodes.first.rawValue ?? "Unknown";
    List<Map<String, dynamic>> dipendenti = await DatabaseHelper.getDipendenti();

    bool isValidQR = false;
    for (var record in dipendenti) {
      var codiceFiscale = record['codiceFiscale'];
      if (scannedData == codiceFiscale) {
        cameraController.stop(); // Ferma la fotocamera prima della navigazione
        isValidQR = true;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(codiceFiscale: codiceFiscale),
          ),
        ).then((_) {
          // Riprendi la fotocamera quando si ritorna alla schermata di login
          cameraController.start();
        });
        break;
      }
    }

    if (!isValidQR) {
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
            _isCameraPermissionGranted
                ? Container(
              height: 300,
              child: MobileScanner(
                controller: cameraController,
                onDetect: _onScan,
              ),
            )
                : Text("Permesso della fotocamera non concesso"),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
