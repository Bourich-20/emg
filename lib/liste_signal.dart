import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_emg_screen.dart';

class ListeSignalScreen extends StatefulWidget {
  final String patientId;
  final bool isAdmin;

  ListeSignalScreen({required this.patientId, required this.isAdmin});

  @override
  _ListeSignalScreenState createState() => _ListeSignalScreenState();
}

class _ListeSignalScreenState extends State<ListeSignalScreen> {
  late Stream<QuerySnapshot> emgDataStream;

  @override
  void initState() {
    super.initState();
    emgDataStream = FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .collection('emgData')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Signaux EMG'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: emgDataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Une erreur est survenue'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune donnée EMG disponible'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index];
              var date = (data['date'] as Timestamp).toDate();
              var formattedDate = '${date.day}/${date.month}/${date.year}';
              var formattedTime = '${date.hour}:${date.minute}:${date.second}';
              var idDec = snapshot.data!.docs[index].id;
              return ListTile(
                title: Text('Data EMG ${index + 1}'),
                subtitle: Text('$formattedDate - $formattedTime'),
                leading: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );
                    FirebaseFirestore.instance
                        .collection('patients')
                        .doc(widget.patientId)
                        .collection('emgData')
                        .doc(idDec)
                        .delete()
                        .then((value) => Navigator.pop(context)); // Close dialog after deletion
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailEmgScreen(
                        patientId: widget.patientId,
                        date: data['date'],
                        idDec: idDec,
                        isAdmin: widget.isAdmin,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
