import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _ageController;
  late final TextEditingController _cinController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false; // État pour contrôler l'affichage du CircularProgressIndicator

  _AccountScreenState() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _ageController = TextEditingController();
    _cinController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account Admin'),
        backgroundColor: Colors.orange, // Couleur de la barre de navigation
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image en haut de la page
            Container(
              padding: EdgeInsets.all(16.0),
              child: Image.asset('assets/emg.jpg'),
            ),
            // Formulaire pour saisir les informations du patient
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(labelText: 'First Name'),
                  ),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(labelText: 'Last Name'),
                  ),
                  TextField(
                    controller: _ageController,
                    decoration: InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _cinController,
                    decoration: InputDecoration(labelText: 'CIN'),
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _savePatient(context),
                    child: _isLoading ? CircularProgressIndicator() : Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // Couleur du bouton
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePatient(BuildContext context) async {
    if (_isLoading) return; // Éviter les enregistrements multiples

    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    String age = _ageController.text;
    String cin = _cinController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    if (firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        age.isNotEmpty &&
        cin.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty) {
      setState(() {
        _isLoading = true; // Afficher le CircularProgressIndicator
      });

      try {
        // Créer l'utilisateur Firebase
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Utiliser l'UID de l'utilisateur comme ID du patient dans Firestore
        String patientId = userCredential.user!.uid;

        // Vérifier si l'email existe déjà dans Firestore
        bool emailExists = await FirebaseFirestore.instance
            .collection('patients')
            .where('email', isEqualTo: email)
            .get()
            .then((querySnapshot) => querySnapshot.docs.isNotEmpty);

        if (emailExists) {
          // Afficher un message indiquant que le compte existe déjà
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An account with this email already exists')),
          );
          // Naviguer vers la page de connexion (login)
          Navigator.pushNamed(context, '/login_screen');
          return;
        }

        // Si l'utilisateur n'existe pas, sauvegarder les informations du patient dans Firestore
        Patient patient = Patient(
          id: patientId,
          firstName: firstName,
          lastName: lastName,
          age: int.parse(age), // Convertir l'âge en int
          cin: cin,
          email: email,
          password: password,
          image: '',
          typePatient: 'Admin',
          ownerId: '',
        );
        await patient.saveToFirestore();

        // Navigation vers la page de connexion (login) après la sauvegarde
        Navigator.pushNamed(context, '/login_screen');

        // Afficher un message indiquant que le compte a été créé avec succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created successfully')),
        );
      } catch (e) {
        // Gérer les erreurs
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create account. Please try again later.')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Masquer le CircularProgressIndicator
        });
      }
    } else {
      // Afficher un message d'erreur si des champs sont vides
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }
}

class Patient {
  late String id;
  late String firstName;
  late String lastName;
  late int age;
  late String cin;
  late String email;
  late String password;
  late String image;
  late String typePatient;
  late String ownerId;
  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.cin,
    required this.email,
    required this.password,
    required this.image,
    required this.typePatient,
    required this.ownerId,
  });

  // Méthode pour convertir les données du patient en map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'cin': cin,
      'email': email,
      'password': password,
      'typePatient' :typePatient,
    };
  }

  // Méthode pour sauvegarder les données du patient dans Cloud Firestore
  Future<void> saveToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('patients').doc(id).set(toMap());
      print('Patient data saved to Firestore');
    } catch (e) {
      print('Failed to save patient data to Firestore: $e');
      throw e;
    }
  }
}
