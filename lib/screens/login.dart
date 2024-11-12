import 'package:flutter/material.dart';
import 'package:managertime/db/DatabaseHelper.dart';
import 'package:managertime/screens/dashboard.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  MobileScannerController cameraController = MobileScannerController();


  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  void _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      print("Permesso fotocamera concesso");
    } else if(status.isPermanentlyDenied){
      print("Permesso fotocamera negato per sempre");
      openAppSettings();
    }else{
      print("Permesso fotocamera negato");
    }
  }
  void _openAppSettings() async {
    bool opened = await openAppSettings();
    if (opened) {
      print("Impostazioni aperte");
    } else {
      print("Impossibile aprire le impostazioni");
    }
  }

  Future<void> _onScan(BarcodeCapture barcodeCapture) async {
    final String scannedData = barcodeCapture.barcodes.first.rawValue ??
        "Unknown";
    //await DatabaseHelper.insertDipendente("Antonio", "Molino", "anto22032005@hotmail.com", "franco");
    //await DatabaseHelper.insertDipendente("Andrea", "Bucelli", "", "topo");
    List<Map<String, dynamic>> dipendenti = await DatabaseHelper.getDipendenti();
    for (var record in dipendenti) {
      var codiceFiscale = record['codiceFiscale'];
      if (scannedData == codiceFiscale) {
        print(codiceFiscale);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(codiceFiscale: codiceFiscale,)),
        );
        break;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Codice QR non valido')),
        );
      }
  }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
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
                onDetect: (BarcodeCapture barcodeCapture) {
                  _onScan(barcodeCapture);
                },
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
