import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to EMG'),
        backgroundColor: Colors.orange, // Couleur orange pour la barre d'application
      ),
      body: Column(
        children: [
          // Image en haut de la page
          Container(
            padding: EdgeInsets.all(16.0),
            child: Image.asset('assets/emg.jpg'), // Assurez-vous d'ajuster le chemin de l'image selon votre arborescence
          ),
          // Boutons sous l'image
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/account_screen');
                  },
                  child: Text('Create Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Couleur du bouton
                    textStyle: TextStyle(color: Colors.white), // Couleur du texte en blanc
                  ),
                ),
                SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login_screen');
                  },
                  child: Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Couleur du bouton
                    textStyle: TextStyle(color: Colors.white), // Couleur du texte en blanc
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.orange,
        // Couleur orange pour la barre d'application en bas
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore EMG World',
                style: TextStyle(
                  color: Colors.white, // Couleur du texte en blanc
                  fontSize: 16.0, // Taille de la police
                  fontWeight: FontWeight.bold, // Poids de la police en gras
                  fontFamily: 'Roboto', // Nom de la police
                ),
              ),
              Text(
                'v1 2024',
                style: TextStyle(
                  color: Colors.white, // Couleur du texte en blanc
                  fontSize: 16.0, // Taille de la police
                  fontWeight: FontWeight.bold, // Poids de la police en gras
                  fontFamily: 'Roboto', // Nom de la police
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
