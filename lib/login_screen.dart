import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'liste_signal.dart';
import 'Home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Instance de FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false; // État pour contrôler l'affichage du CircularProgressIndicato

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.orange, // Couleur de la barre
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(), // Ajouter une bordure aux champs de texte
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(), // Ajouter une bordure aux champs de texte
              ),
              obscureText: true,
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _signInWithEmailAndPassword(context),
              child: _isLoading ? CircularProgressIndicator() : Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Couleur du bouton
              ),
            ),
            SizedBox(height: 10.0),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/reset_password');
                // Par exemple, envoi d'un e-mail de réinitialisation de mot de passe
              },
              child: Text('Forgot Password?'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue, // Couleur du bouton
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour se connecter avec email et mot de passe
  Future<void> _signInWithEmailAndPassword(BuildContext context) async {
    setState(() {
      _isLoading = true; // Définir l'état isLoading à true pour afficher le CircularProgressIndicator
    });

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Récupérer les informations du type de patient à partir de Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('patients').doc(userCredential.user!.uid).get();
      String typePatient = userSnapshot['typePatient'];

      // Naviguer vers la page Home avec l'ID du patient et le type de patient
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(patientId: userCredential.user!.uid, typePatient: typePatient),
        ),
      );
    } catch (error) {
      // Si l'authentification échoue, affichez un message d'erreur
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Invalid email or password. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false; // Définir l'état isLoading à false pour masquer le CircularProgressIndicator
      });
    }
  }
}
