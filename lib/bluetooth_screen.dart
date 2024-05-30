import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


class BluetoothScreen extends StatefulWidget {
  final String patientId;

  BluetoothScreen({required this.patientId});

  @override
  _BluetoothScreenState createState() => _BluetoothScreenState(patientId: patientId);
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final String patientId;
  BluetoothConnection? connection;
  BluetoothDevice? selectedDevice;
  List<BluetoothDevice> devices = [];
  List<int> sensorValues = [];
  bool started = false;
  bool connected = false;
  double minY = 127;
  double maxY = 135;
  Color emgColor = Colors.blue; // Couleur par défaut du graphique EMG

  _BluetoothScreenState({required this.patientId});

  @override
  void initState() {
    super.initState();
    _getBondedDevices();
  }

  Future<void> _getBondedDevices() async {
    List<BluetoothDevice> bondedDevices = [];
    try {
      bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (ex) {
      print("Error retrieving Bluetooth devices: $ex");
    }
    setState(() {
      devices = bondedDevices;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
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
      connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        selectedDevice = device;
        connected = true;
      });
      connection?.input?.listen((Uint8List data) {
        setState(() {
          String receivedData = utf8.decode(data).trim();
          int sensorValue = int.tryParse(receivedData) ?? 0;
          sensorValues.add(sensorValue);
        });
      });
    } catch (error) {
      print("Error connecting to device: $error");
    }

    Navigator.pop(context); // Fermer la boîte de dialogue de chargement
  }

  void _startSendingData() {
    if (connection != null) {
      connection!.output.add(utf8.encode("start"));
      setState(() {
        started = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Demo'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.color_lens),
            onPressed: () => _selectColor(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!connected)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Available Devices:'),
            ),
          if (!connected)
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(devices[index].name ?? ''),
                        Icon(Icons.power),
                      ],
                    ),
                    onTap: () => _connectToDevice(devices[index]),
                  );
                },
              ),
            ),
          if (selectedDevice != null)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Connected to: ${selectedDevice!.name}'),
            ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: started ? _stopSendingData : _startSendingData,
              child: Text(started ? 'Arrêter' : 'Démarrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Couleur du bouton
              ),
            ),
          ),
          if (started)
            Expanded(
              child: EMGChart(
                emgValues: sensorValues.map((value) => value.toDouble()).toList(),
                emgColor: emgColor,
                minY: minY,
                maxY: maxY,
              ),
            ),
          if (started)
            SizedBox(height: 16),
          if (started)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(labelText: 'Valeur minimale (minY)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    minY = double.tryParse(value) ?? minY;
                  });
                },
                style: TextStyle(color: Colors.orange),
              ),
            ),
          if (started)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(labelText: 'Valeur maximale (maxY)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    maxY = double.tryParse(value) ?? maxY;
                  });
                },
                style: TextStyle(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  void _stopSendingData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    if (connection != null) {
      connection!.output.add(utf8.encode("stop"));
      setState(() {
        started = false;
      });

      await _saveEMGDataToFirestore();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('EMG data saved to Firestore'),
        ),
      );

      Navigator.of(context).pop(widget.patientId);
    }

    Navigator.pop(context); // Fermer la boîte de dialogue de chargement
  }

  Future<void> _saveEMGDataToFirestore() async {
    try {
      CollectionReference patientCollection = FirebaseFirestore.instance.collection('patients');

      Map<String, dynamic> emgData = {
        'date': DateTime.now(),
        'emgValues': sensorValues,
        'minY': minY,
        'maxY': maxY,
      };

      DocumentReference documentReference = await patientCollection
          .doc(widget.patientId)
          .collection('emgData')
          .add(emgData);

      String documentId = documentReference.id;
      print('ID du document créé : $documentId');

      print('EMG data saved to Firestore');
    } catch (error) {
      print('Error saving EMG data to Firestore: $error');
    }
  }

  void _selectColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisir une couleur'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: emgColor,
              onColorChanged: (Color color) {
                setState(() {
                  emgColor = color;
                });
              },
            ),
          ),
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

  @override
  void dispose() {
    super.dispose();
    connection?.dispose();
  }
}

class EMGChart extends StatefulWidget {
  final List<double> emgValues;
  final Color emgColor;
  final double minY;
  final double maxY;

  const EMGChart({
    required this.emgValues,
    required this.emgColor,
    required this.minY,
    required this.maxY,
  });

  @override
  _EMGChartState createState() => _EMGChartState();
}

class _EMGChartState extends State<EMGChart> {
  late double _minX;
  late double _maxX;

  @override
  void initState() {
    super.initState();
    _minX = 0;
    _maxX = widget.emgValues.length.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> emgPoints = List.generate(
      widget.emgValues.length,
          (index) => FlSpot(index.toDouble(), widget.emgValues[index]),
    );

    return AspectRatio(
      aspectRatio: 2.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: LineChart(
          LineChartData(
            minY: widget.minY,
            maxY: widget.maxY,
            minX: _minX,
            maxX: _maxX,
            lineTouchData: const LineTouchData(enabled: false),
            clipData: const FlClipData.all(),
            gridData: const FlGridData(
              show: true,
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              emgLine(emgPoints),
            ],
            titlesData: const FlTitlesData(
              show: false,
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData emgLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: const FlDotData(
        show: false,
      ),
      gradient: LinearGradient(
        colors: [widget.emgColor.withOpacity(0), widget.emgColor],
        stops: const [0.1, 1.0],
      ),
      barWidth: 4,
      isCurved: false,
    );
  }

  void _updateXAxis() {
    setState(() {
      _minX = _minX + 0.90;
      _maxX = _maxX + 0.90;
    });
  }

  @override
  void didUpdateWidget(covariant EMGChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateXAxis();
  }
}
