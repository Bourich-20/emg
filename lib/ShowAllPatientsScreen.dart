import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emg/profil.dart';
import 'package:emg/liste_signal.dart';

class ShowAllPatientsScreen extends StatelessWidget {
  final String patientId;

  ShowAllPatientsScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Patients',
          style: TextStyle(color: Colors.white), // Couleur du texte de l'en-tête
        ),
        backgroundColor: Colors.orange, // Couleur de l'arrière-plan de l'en-tête
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('patients').where('ownerId', isEqualTo: patientId).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No patients found'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot patient = snapshot.data!.docs[index];
              return ListTile(
                title: Text('${patient['firstName']} ${patient['lastName']}'),
                subtitle: Text('Age: ${patient['age']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.person, color: Colors.blue), // Couleur de l'icône bleue
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(patientId: patient.id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );

                        try {
                          // Récupérer l'ID de l'utilisateur associé au patient depuis Firestore
                          String? userId = await FirebaseFirestore.instance.collection('patients').doc(patient.id).get()
                              .then((snapshot) => snapshot.data()?['userId']);

                          // Vérifier que l'ID de l'utilisateur est disponible
                          if (userId != null) {
                            // Récupérer l'utilisateur correspondant à l'ID
                            User? user = await FirebaseAuth.instance.userChanges().firstWhere((user) => user?.uid == userId);

                            if (user != null) {
                              // Supprimer l'utilisateur de Firebase Auth
                              await user.delete();
                              print('User deleted successfully');
                            }
                          }

                          // Supprimer le patient de Firestore
                          await FirebaseFirestore.instance.collection('patients').doc(patient.id).delete();

                          Navigator.pop(context); // Fermer la boîte de dialogue de chargement
                        } catch (e) {
                          print('Error deleting patient: $e');
                          // Gérer l'erreur si la suppression échoue
                          Navigator.pop(context); // Fermer la boîte de dialogue de chargement
                          // Afficher un message d'erreur à l'utilisateur
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Error'),
                                content: Text('Failed to delete patient. Please try again later.'),
                                actions: <Widget>[
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
                        }
                      },
                    ),

                    IconButton(
                      icon: Icon(Icons.list, color: Colors.green), // Couleur de l'icône de liste verte
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListeSignalScreen(patientId: patient.id,isAdmin:true),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
