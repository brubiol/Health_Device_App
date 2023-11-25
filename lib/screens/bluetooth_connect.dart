import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:health_device_app/models/metric.dart';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  BluetoothConnection? connection;
  bool isConnecting = true;
  List<String> logs = []; // List to hold log messages

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
    String dataString = String.fromCharCodes(data);
    final tempMatch = RegExp(r'Temp: (\d+\.\d+)C').firstMatch(dataString);
    final bpmMatch = RegExp(r'BPM: (\d+)').firstMatch(dataString);
    final spo2Match = RegExp(r'SpO2: (\d+)%').firstMatch(dataString);

    setState(() {
      if (tempMatch != null) metrics[2].value = tempMatch.group(1) ?? 'N/A';
      if (bpmMatch != null) metrics[0].value = bpmMatch.group(1) ?? 'N/A';
      if (spo2Match != null) metrics[1].value = spo2Match.group(1) ?? 'N/A';
    });
  }

  void disconnectFromDevice() {
    if (connection != null && connection!.isConnected) {
      connection!.dispose();
      log('Disconnected from device');
      setState(() {
        isConnecting = true;
        connection = null;
      });
    }
  }

  @override
  void dispose() {
    disconnectFromDevice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Metrics'),
      ),
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
    );
  }
}
