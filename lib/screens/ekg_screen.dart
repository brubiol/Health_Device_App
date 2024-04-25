import 'dart:async';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class EKGScreen extends StatefulWidget {
  @override
  _EKGScreenState createState() => _EKGScreenState();
}

class _EKGScreenState extends State<EKGScreen> {
  List<FlSpot> ekgPoints = [];
  BluetoothConnection? connection;
  String latestData = "Waiting for data...";
  bool isConnecting = true;
  Timer? updateTimer;

  @override
  void initState() {
    super.initState();
    initBluetooth();
    updateTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {}); // This will trigger the UI update periodically
      }
    });
  }

  void initBluetooth() async {
    const String deviceAddress =
        'D4:8A:FC:9E:5C:32'; // Replace with the actual device's Bluetooth MAC address
    try {
      connection = await BluetoothConnection.toAddress(deviceAddress);
      setState(() {
        isConnecting = false;
      });
      connection!.input!.listen(_onDataReceived).onDone(() {
        if (connection != null && connection!.isConnected) {
          connection!.dispose();
        }
        if (mounted) {
          setState(() {
            isConnecting = true;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          latestData = "Connection Failed: $e";
          isConnecting = false;
        });
      }
    }
  }

  void _onDataReceived(Uint8List data) {
    String dataString = String.fromCharCodes(data).trim();
    var lines = dataString.split('\n');
    for (var line in lines) {
      if (line.startsWith('EKG,')) {
        var parts = line.split(',');
        if (parts.length >= 6) {
          // Assuming the correct number of data points is received
          try {
            double ekgValue = double.parse(parts[1]);

            // Optionally, manage the x-axis value if needed or keep it sequential
            double xValue = ekgPoints.isNotEmpty ? ekgPoints.last.x + 1 : 0;

            // Here we are adding a new data point
            FlSpot newSpot = FlSpot(xValue, ekgValue);

            setState(() {
              // Add the new spot to your data list
              ekgPoints.add(newSpot);

              // Remove the oldest data point to keep the graph at a fixed size
              if (ekgPoints.length > 100) {
                ekgPoints.removeAt(0);
              }

              // Update the latest data display text
              latestData = 'EKG Value: $ekgValue';
            });
          } catch (e) {
            print('Error parsing EKG data: $e');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EKG Data Stream'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: isConnecting
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: ekgPoints,
                            isCurved: false,
                            barWidth: 2,
                            color: Colors.red,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          )
                        ],
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              latestData,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    //updateTimer?.cancel();
    //connection?.dispose();
    //super.dispose();
  }
}
