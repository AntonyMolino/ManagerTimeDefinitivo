import 'package:flutter/material.dart';
import 'package:managertime/db/Dipendente.dart';
import 'package:managertime/screens/admin_login_page.dart';
import 'package:managertime/screens/dashboard.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isCameraPermissionGranted = false;
  Map<String, String> _dipendentiMap = {}; // Mappa codice fiscale -> dettagli

  @override
  void initState() {
    super.initState();
    _initializeApp();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initializeApp() async {
    await _requestCameraPermission();
    await _loadDipendentiData();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isCameraPermissionGranted = true);
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _loadDipendentiData() async {
    final dipendenti = await Dipendente.getDipendenti();
    setState(() {
      _dipendentiMap = {
        for (var record in dipendenti)
          record['codiceFiscale']: record['details'] ?? '',
      };
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController.start();
    }
  }

  Future<void> _onScan(BarcodeCapture barcodeCapture) async {
    final String scannedData = barcodeCapture.barcodes.first.rawValue ?? "Unknown";
    final isValidQR = _dipendentiMap.containsKey(scannedData);

    if (!isValidQR) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Codice QR non valido')),
      );
      return;
    }

    _cameraController.stop(); // Ferma la fotocamera prima di navigare

    if (scannedData == "admin") {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminLoginPage()),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(codiceFiscale: scannedData),
        ),
      );
    }

    _cameraController.start(); // Riprendi la fotocamera al ritorno
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
        title: Text(
          'Sistema di Registrazione',
          style: TextStyle(color: Colors.white),
        ),
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
            if (_isCameraPermissionGranted)
              Container(
                height: 300,
                child: MobileScanner(
                  controller: _cameraController,
                  onDetect: _onScan,
                ),
              )
            else
              Center(child: Text("Permesso della fotocamera non concesso")),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
