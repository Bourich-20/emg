import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DetailEmgScreen extends StatefulWidget {
  final String patientId;
  final Timestamp date;
  final String idDec;
  final bool isAdmin;

  DetailEmgScreen({
    required this.patientId,
    required this.date,
    required this.idDec,
    required this.isAdmin,
  });

  @override
  _DetailEmgScreenState createState() => _DetailEmgScreenState();
}

class _DetailEmgScreenState extends State<DetailEmgScreen> {
  List<double> emgValues = [];
  double minY = 0;
  double maxY = 0;
  double _minX = -400;
  double _maxX = 0;
  late Timer _timer;
  final double scrollSpeed = 0.9;

  TextEditingController _commentController = TextEditingController();
  String? _comment;
  String? _commentDate;
  bool _editMode = false;
  Color _selectedColor = Colors.blue; // Couleur par défaut

  @override
  void initState() {
    super.initState();
    _fetchAndSetEmgValues(widget.patientId, widget.idDec);
    _fetchComment();
  }

  Future<void> _fetchAndSetEmgValues(String patientId, String iDoc) async {
    try {
      List<double> fetchedEmgValues = await fetchEmgValues(patientId, iDoc);
      setState(() {
        emgValues = fetchedEmgValues;
        _minX = emgValues.length.toDouble();
        _maxX = 0;
        _startScrollAnimation();
      });
    } catch (error) {
      print('Error fetching emgValues: $error');
    }
  }

  Future<List<double>> fetchEmgValues(String patientId, String iDoc) async {
    try {
      CollectionReference emgDataCollection = FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('emgData');

      DocumentSnapshot documentSnapshot =
      await emgDataCollection.doc(iDoc).get();

      if (documentSnapshot.exists) {
        List<dynamic> emgValuesData = documentSnapshot['emgValues'];
        List<double> emgValues = [];
        minY = documentSnapshot['minY'].toDouble();
        maxY = documentSnapshot['maxY'].toDouble();
        for (var value in emgValuesData) {
          if (value is double) {
            emgValues.add(value);
          } else if (value is int) {
            emgValues.add(value.toDouble());
          }
        }
        return emgValues;
      } else {
        throw Exception('Document does not exist');
      }
    } catch (error) {
      print('Error fetching emgValues: $error');
      throw error;
    }
  }

  Future<void> _fetchComment() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('emgData')
          .doc(widget.idDec)
          .get();
      if (doc.exists) {
        setState(() {
          _comment = doc['comment'];
          Timestamp timestamp = doc['timestamp'];
          _commentDate = timestamp.toDate().toString();
        });
      }else{
        _comment ='';
        Timestamp timestamp = Timestamp.now();
        _commentDate = '';
      }
    } catch (error) {
      print('Error fetching comment: $error');
    }
  }

  void _startScrollAnimation() {
    _timer = Timer.periodic(Duration(milliseconds: 20), (timer) {
      setState(() {
        _minX += scrollSpeed;
        _maxX += scrollSpeed;
      });
    });
  }

  void _scrollToTop() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DetailEmgScreen(
          patientId: widget.patientId,
          date: widget.date,
          idDec: widget.idDec,
          isAdmin: widget.isAdmin,
        ),
      ),
    );
  }

  void _editComment() {
    _commentController.text = _comment ?? '';
    setState(() {
      _editMode = true; // Changer false en true
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('emgData')
          .doc(widget.idDec)
          .set(
        {
          'comment': _commentController.text,
          'timestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      setState(() {
        _comment = _commentController.text;
        _commentDate = DateTime.now().toString();
        _commentController.clear();
        _editMode = false; // Changer true en false
      });
    }
  }

  Future<void> _selectColor() async {
    Color? color = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisir une couleur'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Valider'),
              onPressed: () {
                Navigator.of(context).pop(_selectedColor);
              },
            ),
          ],
        );
      },
    );

    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail EMG'),
        backgroundColor: Colors.orange, // Couleur de la barre de titre
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _selectedColor), // Icône avec couleur sélectionnée
            onPressed: _scrollToTop,
          ),
          IconButton(
            icon: Icon(Icons.color_lens, color: _selectedColor), // Icône avec couleur sélectionnée
            onPressed: _selectColor,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Date: ${widget.date.toDate()}',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: EMGChart(
              emgValues: emgValues.map((value) => value.toDouble()).toList(),
              emgColor: _selectedColor, // Utilisation de la couleur sélectionnée
              minY: minY,
              maxY: maxY,
              minX: _minX,
              maxX: _maxX,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _editMode
                ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Commentaire',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.save, color: _selectedColor), // Icône avec couleur sélectionnée
                  onPressed: _submitComment,
                ),
              ],
            )
                : _comment != null || _comment == null
                ? ListTile(
              title: Text(
                _comment ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Date: ${_commentDate ?? 'message for dector'}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              trailing: widget.isAdmin
                  ? IconButton(
                icon: Icon(Icons.edit, color: _selectedColor), // Icône avec couleur sélectionnée
                onPressed: _editComment,
              )
                  : null,
            )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class EMGChart extends StatelessWidget {
  final List<double> emgValues;
  final Color emgColor;
  final double minY;
  final double maxY;
  final double minX;
  final double maxX;

  const EMGChart({
    required this.emgValues,
    required this.emgColor,
    required this.minY,
    required this.maxY,
    required this.minX,
    required this.maxX,
  });

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> emgPoints = emgValues.asMap().entries.map((entry) {
      final index = entry.key * 6;
      final value = entry.value;
      return FlSpot(index.toDouble(), value);
    }).toList();

    return AspectRatio(
      aspectRatio: 2.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            minX: minX,
            maxX: maxX,
            lineTouchData: const LineTouchData(enabled: false),
            clipData: const FlClipData.all(),
            gridData: const FlGridData(
              show: true,
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              emgLine(emgPoints, emgColor), // Passer la couleur ici
            ],
            titlesData: const FlTitlesData(
              show: false,
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData emgLine(List<FlSpot> points, Color color) { // Ajouter un paramètre de couleur
    return LineChartBarData(
      spots: points,
      dotData: const FlDotData(
        show: false,
      ),
      gradient: LinearGradient(
        colors: [color.withOpacity(0), color], // Utiliser la couleur passée
        stops: const [0.1, 1.0],
      ),
      barWidth: 4,
      isCurved: false,
    );
  }
}
