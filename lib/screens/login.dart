import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static MobileScannerController cameraController = MobileScannerController();
  bool _isCameraPermissionGranted = false;
  bool isDialogOpen = false; // Variabile per controllare i dialoghi

  @override
  void initState() {
    super.initState();
    _initializeApp();
    WidgetsBinding.instance.addObserver(this); // Osserva il ciclo di vita
    cameraController.start(); // Avvia la fotocamera
  }

  Future<void> _initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Now you can safely call SystemChrome.setPreferredOrientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await _requestCameraPermission();
  }

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      cameraController.stop(); // Ferma la fotocamera quando l'app è in background
    } else if (state == AppLifecycleState.resumed) {
      cameraController.start(); // Riavvia la fotocamera quando l'app torna in foreground
    }
  }

  Future<void> _onScan(BarcodeCapture barcodeCapture) async {
    String scannedData = barcodeCapture.barcodes.first.rawValue ?? "Unknown";
    scannedData = scannedData.trim();

    final dipendenti = await Dipendente.getDipendenti();
    bool isValidQR = dipendenti.any((record) => record['codiceFiscale'] == scannedData);

    if (!isValidQR) {
      if (!isDialogOpen) {
        isDialogOpen = true; // Imposta `isDialogOpen` a `true` prima di mostrare il dialogo
        cameraController.stop(); // Ferma la fotocamera
        _showErrorDialog("Codice QR non valido").then((_) {
          isDialogOpen = false; // Reimposta `isDialogOpen` a `false` dopo aver chiuso il dialogo
          cameraController.start(); // Riavvia la fotocamera
        });
      }
    } else {
      cameraController.stop(); // Ferma la fotocamera prima di navigare
      if (scannedData == "admin") {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdminLoginPage()),
              (route) => false,
        ).then((_) => cameraController.start()); // Riavvia la fotocamera al ritorno
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage(codiceFiscale: scannedData)),
              (route) => false,
        ).then((_) => cameraController.start());
      }
    }
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Errore" , style: TextStyle(color: Colors.white),),
        content: Text("Errore nella lettura del qr code , Premere 'Riprova' per continuare e scannerizzare un nuovo qr" , style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.red,

        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Chiudi il dialogo
            },
            child: Text("Riprova", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.jpg', fit: BoxFit.contain),
        ),
        title: Text('Sistema di Registrazione', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scansiona il codice QR per accedere:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            if (_isCameraPermissionGranted)
              Transform.rotate(
                angle: -90 * 3.14159 / 180, // Ruota la fotocamera di 90 gradi
                child: Container(
                  height: 300,
                  child: MobileScanner(
                    controller: cameraController,
                    onDetect: _onScan,
                  ),
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
