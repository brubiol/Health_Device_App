import 'package:flutter/material.dart';
import 'package:health_device_app/screens/bluetooth_connect.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Device App',
      home: BluetoothScreen(),
    );
  }
}
