import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:health_device_app/models/db_helper.dart'; // Ensure this path is correct
import 'package:health_device_app/models/metric.dart';
import 'package:health_device_app/screens/ekg_screen.dart';
import 'package:intl/intl.dart';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  BluetoothConnection? connection;
  bool isConnecting = true;
  List<String> logs = []; // List to hold log messages
  List<Map<String, dynamic>> savedReadings = []; // To store readings from DB
  List<int> ekgData = [];

  List<Metric> metrics = [
    Metric(
        title: 'Heart Rate',
        value: '...',
        icon: Icons.favorite,
        color: Colors.red),
    Metric(
        title: 'Blood Oxygen',
        value: '...',
        icon: Icons.opacity,
        color: Colors.blue),
    Metric(
        title: 'Temperature',
        value: '...',
        icon: Icons.thermostat,
        color: Colors.orange),
  ];

  @override
  void initState() {
    super.initState();
    startBluetoothConnection();
    fetchReadingsFromDB(); // Fetch readings from DB on init
  }

  void fetchReadingsFromDB() async {
    var readings = await DBHelper.instance.getReadings();
    setState(() {
      savedReadings = readings;
    });
  }

  void log(String message) {
    setState(() {
      logs.add(message);
    });
  }

  void startBluetoothConnection() async {
    log('Starting Bluetooth connection...');
    try {
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      log('Bonded Devices: ${devices.map((e) => e.name).join(', ')}');

      for (BluetoothDevice device in devices) {
        if (device.name == 'ESP32_Health_Monitor') {
          log('Attempting to connect to ${device.name}');
          await connectToDevice(device);
          break;
        }
      }
    } catch (error) {
      log('Connection error: $error');
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address)
          .timeout(Duration(seconds: 10));
      log('Connected to the device');
      setState(() => isConnecting = false);

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (this.connection != null && this.connection!.isConnected) {
          disconnectFromDevice();
        }
      });
    } on TimeoutException catch (_) {
      log('Connection to device timed out');
    } catch (error) {
      log('Connection error: $error');
    }
  }

  void _onDataReceived(Uint8List data) {
    // Convert Uint8List to a string
    String dataString = String.fromCharCodes(data);
    // Assuming that each message from the Arduino ends with a newline character.
    var lines = dataString.split('\n');
    for (var line in lines) {
      // Skip empty lines
      if (line.trim().isEmpty) continue;

      // Check if the line contains EKG data
      if (line.startsWith('EKG,')) {
        var parts = line.split(',');
        // Parse EKG data parts
        if (parts.length >= 6) {
          double? newData = double.tryParse(parts[1]);
          double? avgData = double.tryParse(parts[2]);
          double? scaledAvgData = double.tryParse(parts[3]);
          double? maxData = double.tryParse(parts[4]);
          double? beatsPerMinute = double.tryParse(parts[5]);
        }
      } else {
        // Handle other data types like Temp, BPM, and SpO2
        final tempMatch = RegExp(r'Temp: (\d+\.\d+)C').firstMatch(line);
        final bpmMatch = RegExp(r'BPM: (\d+)').firstMatch(line);
        final spo2Match = RegExp(r'SpO2: (\d+)%').firstMatch(line);

        double? temperature =
            tempMatch != null ? double.tryParse(tempMatch.group(1)!) : null;
        int? bpm = bpmMatch != null ? int.tryParse(bpmMatch.group(1)!) : null;
        int? spo2 =
            spo2Match != null ? int.tryParse(spo2Match.group(1)!) : null;

        setState(() {
          if (temperature != null) metrics[2].value = '${temperature}°C';
          if (bpm != null) metrics[0].value = '$bpm BPM';
          if (spo2 != null) metrics[1].value = '$spo2%';
        });

        // Save to DB
        if (temperature != null && bpm != null && spo2 != null) {
          DBHelper.instance.insertReading(temperature, bpm, spo2);
        }

        // Fetch updated readings
        fetchReadingsFromDB();
      }
    }
  }

  void disconnectFromDevice() {
    if (connection != null && connection!.isConnected) {
      //connection!.dispose();
      log('Disconnected from device');
      setState(() {
        isConnecting = true;
        connection = null;
      });
    }
  }

  @override
  void dispose() {
    //disconnectFromDevice();
    //super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Metrics')),
      body: Column(
        children: [
          Expanded(
            child: isConnecting
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: metrics.length,
                    itemBuilder: (context, index) {
                      Metric metric = metrics[index];
                      return ListTile(
                        leading: Icon(metric.icon, color: metric.color),
                        title: Text(metric.title),
                        trailing: Text(metric.value),
                      );
                    },
                  ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: savedReadings.length,
              itemBuilder: (context, index) {
                var reading = savedReadings[index];
                return ListTile(
                  title: Text(
                      'Temperature: ${reading['temperature']}°C, BPM: ${reading['bpm']}, SpO2: ${reading['spo2']}%'),
                  subtitle: Text(
                    'Timestamp: ${DateFormat('yyyy-MM-dd h:mma').format(DateTime.fromMillisecondsSinceEpoch(reading['timestamp']))}',
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(logs[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EKGScreen(),
            ),
          );
        },
        child: Icon(Icons.auto_graph_outlined),
        tooltip: 'Go to EKG Screen',
      ),
    );
  }
}
