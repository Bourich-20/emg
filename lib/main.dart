import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importez Firebase Core

import 'welcome_screen.dart';
import 'bluetooth_screen.dart';
import 'profil.dart';
import 'account_screen.dart';
import 'login_screen.dart';
import 'reset_password.dart';
import 'profil.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

   await Firebase.initializeApp(options: FirebaseOptions(
     apiKey: "AIzaSyA-UbvSTJ81bsuiKZhozyUzxZ-IuQa-OgU",
     appId: "1:690717939270:android:2dc4ad3a5a7da433811c47",
     messagingSenderId: "690717939270",
     projectId: "projetemg-20e32",
    ));



  // Lancez votre application Flutter
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/account_screen': (context) => AccountScreen(), // Définissez la route '/account_screen'
        '/login_screen': (context) => LoginScreen(), // Définissez la route '/login_screen'
        '/reset_password': (context) => ResetPasswordPage(),




      },
    );
  }
}
