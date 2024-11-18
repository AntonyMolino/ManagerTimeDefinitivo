import 'package:flutter/material.dart';
import 'adminpage.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _passwordController = TextEditingController();
  final String _correctPassword = "";
  void _checkPassword() {
    if (_passwordController.text == _correctPassword) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password errata')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accesso Admin',
        style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 100 , right: 100),
                child: Text(
                  'Inserisci la password per accedere alla pagina admin:',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 120 , right: 120),
                child: TextField(

                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPassword,
                child: Text('Accedi',
                style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
