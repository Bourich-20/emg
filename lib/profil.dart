import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String patientId;

  ProfileScreen({required this.patientId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _patientData = {};
  late bool _isCurrentUser;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = FirebaseAuth.instance.currentUser!.uid == widget.patientId;
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    try {
      DocumentSnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();
      if (querySnapshot.exists) {
        setState(() {
          _patientData = querySnapshot.data() as Map<String, dynamic>;
        });
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error fetching patient data: $e');
    }
  }

  Future<void> _updatePatientData(Map<String, dynamic> newData) async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update(newData);
      // Rafraîchir les données après la mise à jour
      await _fetchPatientData();
      Navigator.pop(context); // Close dialog after update
    } catch (e) {
      print('Error updating patient data: $e');
    }
  }

  Future<void> _updateProfilePicture(File imageFile) async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      final imageName = '${DateTime.now().millisecondsSinceEpoch}';
      final firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('images/$imageName');
      final uploadTask = firebaseStorageRef.putFile(imageFile);
      await uploadTask.whenComplete(() => null);
      final imageUrl = await firebaseStorageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({'image': imageUrl});
      // Rafraîchir les données après la mise à jour de l'image
      await _fetchPatientData();
      Navigator.pop(context); // Close dialog after update
    } catch (e) {
      print('Error updating profile picture: $e');
    }
  }

  void _showEditProfileDialog() {
    String newFirstName = _patientData['firstName'];
    String newLastName = _patientData['lastName'];
    int newAge = _patientData['age'];
    String newCin = _patientData['cin'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier le profil'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Nom'),
                  controller: TextEditingController(text: newLastName),
                  onChanged: (value) => newLastName = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Prénom'),
                  controller: TextEditingController(text: newFirstName),
                  onChanged: (value) => newFirstName = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Âge'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: newAge.toString()),
                  onChanged: (value) => newAge = int.tryParse(value) ?? 0,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'CIN'),
                  controller: TextEditingController(text: newCin),
                  onChanged: (value) => newCin = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // Mettre à jour les données du patient
                _updatePatientData({
                  'firstName': newFirstName,
                  'lastName': newLastName,
                  'age': newAge,
                  'cin': newCin,
                });
                Navigator.of(context).pop();
              },
              child: Row(
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text('Enregistrer'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImagePicker() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _updateProfilePicture(imageFile); // Mettre à jour l'image du profil
    } else {
      print('Aucune image sélectionnée.');
    }
  }

  void _showEditPasswordDialog() {
    String newPassword = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier le mot de passe'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
                  onChanged: (value) => newPassword = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Mettre à jour le mot de passe dans Firebase Auth
                  await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mot de passe mis à jour avec succès')),
                  );
                } catch (e) {
                  print('Error updating password: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la mise à jour du mot de passe')),
                  );
                }
              },
              child: Row(
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text('Changer'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        backgroundColor: Colors.orange,
      ),
      body: _patientData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (_isCurrentUser) _showImagePicker();
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _patientData != null && _patientData.containsKey('image')
                      ? NetworkImage(_patientData['image'] as String)
                      : AssetImage('assets/profil.jpg') as ImageProvider<Object>,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Nom: ${_patientData['lastName']}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Prénom: ${_patientData['firstName']}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Âge: ${_patientData['age']}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'CIN: ${_patientData['cin']}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Email: ${_patientData['email']}',
                style: TextStyle(fontSize: 18),
              ),
              if (_isCurrentUser)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _showEditProfileDialog();
                      },
                      icon: Icon(Icons.edit, color: Colors.blue),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      label: Text('Modifier le profil'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showEditPasswordDialog();
                      },
                      icon: Icon(Icons.lock, color: Colors.green),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      label: Text('Modifier le mot de passe'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

}
