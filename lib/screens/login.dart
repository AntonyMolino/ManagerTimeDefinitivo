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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  // Initialization methods
  Future<void> _initializeApp() async {
    await _requestCameraPermission();
  }

  // Request camera permission for scanning QR codes
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _isCameraPermissionGranted = status.isGranted;
    });

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController.start();
    }
  }

  // Handle the scanned QR code
  Future<void> _onScan(BarcodeCapture barcodeCapture) async {
    String scannedData = barcodeCapture.barcodes.first.rawValue ?? "Unknown";
    scannedData = scannedData.trim();
    // Fetch the list of dipendenti (employees) from the database
    final dipendenti = await Dipendente.getDipendenti();

    // Search for a matching codiceFiscale
    bool isValidQR = false;
    for (var record in dipendenti) {
      if (record['codiceFiscale'] == scannedData) {
        isValidQR = true;
        break;
      }
    }

    if (!isValidQR) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Codice QR non valido')));
      return;
    }

    _cameraController.stop(); // Stop camera before navigation

    // Navigate based on scanned QR code

    if (scannedData == "admin") {
      if(!context.mounted) return;
      await Navigator.push(
          context, MaterialPageRoute(builder: (context) => AdminLoginPage()));
    } else {
      if(!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(codiceFiscale: scannedData)),
      );
    }

    _cameraController.start(); // Restart camera after navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.jpg', fit: BoxFit.contain),
        ),
        title: Text('Sistema di Registrazione',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scansiona il codice QR per accedere:',
                style: TextStyle(fontSize: 18)),
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
