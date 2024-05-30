import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ShowAllPatientsScreen.dart';

class AddPatientScreen extends StatelessWidget {
  final String ownerId;

  AddPatientScreen({required this.ownerId}) {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _ageController = TextEditingController();
    _cinController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController(text: '123456'); // Mot de passe par défaut
  }

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _ageController;
  late final TextEditingController _cinController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Patient'),
        backgroundColor: Colors.orange, // Couleur de la barre en haut
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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

                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () {
                      _savePatient(context);
                    },
                    child: Text('Save'),
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
    // Afficher la boîte de dialogue de chargement avec CircularProgressIndicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    int age = int.tryParse(_ageController.text) ?? 0;
    String cin = _cinController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    if (firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        age > 0 &&
        cin.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String patientId = userCredential.user!.uid;

        bool emailExists = await FirebaseFirestore.instance
            .collection('patients')
            .where('email', isEqualTo: email)
            .get()
            .then((querySnapshot) => querySnapshot.docs.isNotEmpty);

        if (emailExists) {
          // Fermer la boîte de dialogue de chargement
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An account with this email already exists')),
          );
          return;
        }

        Patient patient = Patient(
          id: patientId,
          firstName: firstName,
          lastName: lastName,
          age: age,
          cin: cin,
          email: email,
          password: password,
          image: '',
          typePatient: 'Patient',
          ownerId: ownerId,
        );
        await patient.saveToFirestore();

        // Envoyer le mot de passe par e-mail au nouveau patient
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        // Fermer la boîte de dialogue de chargement
        Navigator.pop(context);

        // Naviguer vers ShowAllPatientsScreen avec le patientId comme paramètre
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShowAllPatientsScreen(patientId: ownerId),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient added successfully')),
        );
      } catch (e) {
        // Fermer la boîte de dialogue de chargement
        Navigator.pop(context);

        print('Error: $e');
      }
    } else {
      // Fermer la boîte de dialogue de chargement
      Navigator.pop(context);

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'cin': cin,
      'email': email,
      'password': password,
      'typePatient': typePatient,
      'ownerId': ownerId,
    };
  }

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
