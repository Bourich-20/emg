import 'package:flutter/material.dart';
import 'AddPatientScreen.dart';
import 'ShowAllPatientsScreen.dart';
import 'profil.dart';
import 'bluetooth_screen.dart';
import 'liste_signal.dart';
import 'AddPatientScreen.dart';

class HomeScreen extends StatelessWidget {
  final String patientId;
  final String typePatient; // Ajouter le type de patient

  HomeScreen({required this.patientId, required this.typePatient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.orange, // Couleur d'arrière-plan de la barre d'applications
        actions: [
          if (typePatient == 'Admin') // Vérifier si le type de patient est admin
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text('Add Patient'),
                  value: 'add_patient',
                ),
                PopupMenuItem(
                  child: Text('Show All Patients'),
                  value: 'show_all_patients',
                ),
              ],
              onSelected: (value) {
                if (value == 'add_patient') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPatientScreen(ownerId: patientId),
                    ),
                  );
                } else if (value == 'show_all_patients') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowAllPatientsScreen(patientId: patientId),
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: Icon(Icons.account_circle),
            color: Colors.white, // Couleur de l'icône
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(patientId: patientId),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white, // Couleur d'arrière-plan du Scaffold
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20), // Espacement entre l'image et les boutons
            Image.asset(
              'assets/signal.gif', // Chemin de l'image
              width: 100, // Largeur de l'image
              height: 100, // Hauteur de l'image
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BluetoothScreen(patientId: patientId),
                  ),
                );
              },
              child: Text('Traitement', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Couleur du bouton
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListeSignalScreen(patientId: patientId, isAdmin: false),
                  ),
                );
              },
              child: Text('Liste des Signaux', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Couleur du bouton
              ),
            ),
          ],
        ),
      ),
    );
  }
}
