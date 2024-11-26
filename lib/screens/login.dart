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
  bool isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    WidgetsBinding.instance.addObserver(this); // Observe lifecycle changes
    print("inizializzo login");
  }

  // Initialize app by requesting camera permissions
  Future<void> _initializeApp() async {
    await _requestCameraPermission();
  }

  // Request camera permission
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

  // Lifecycle method for when the app state changes (in background/foreground)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController.stop(); // Stop camera when app is backgrounded
    } else if (state == AppLifecycleState.resumed) {
      _cameraController.start(); // Restart camera when app is resumed
    }
  }

  // Handle QR scan
  Future<void> _onScan(BarcodeCapture barcodeCapture) async {
    String scannedData = barcodeCapture.barcodes.first.rawValue ?? "Unknown";
    scannedData = scannedData.trim();

    // Fetch employees from database
    final dipendenti = await Dipendente.getDipendenti();

    // Validate the scanned QR code
    bool isValidQR = false;
    for (var record in dipendenti) {
      if (record['codiceFiscale'] == scannedData) {
        isValidQR = true;
        break;
      }
    }

    if (!isValidQR) {
      if (!isDialogOpen) {
        isDialogOpen = true;
        _cameraController.stop(); // Stop camera

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Errore", style: TextStyle(color: Colors.white)),
              content: Text(
                "Codice QR non valido",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              backgroundColor: Colors.red,
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    isDialogOpen = false;
                    await Future.delayed(Duration(milliseconds: 100));
                    print("Premo OK");
                    _cameraController.start(); // Restart camera after dialog
                  },
                  child: Text(
                    "Ok",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      }
    } else {
      _cameraController.stop(); // Stop camera before navigation

      // Navigate based on QR code scan
      if (scannedData == "admin") {
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminLoginPage()),
        ).then((value) {
          _cameraController.start();
        },);
      } else {
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage(codiceFiscale: scannedData)),
        ).then((value) {
          _cameraController.start();
        },);
      }

      _cameraController.start(); // Restart camera after navigation
    }
  }

  // This method will be triggered when the current screen is popped off the navigation stack
  void didPopNext() {
    // This will restart the camera when returning to this screen
    _cameraController.start();
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
