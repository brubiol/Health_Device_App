
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health_device_app/screens/home_page.dart';
import 'constants/styles.dart';
import 'models/metric.dart';

List<Metric> metrics = [
  Metric(title: 'Heart Rate', value: '56', icon: Icons.favorite_border_sharp, color: Color(0xFF101213)),
  Metric(title: 'Blood Oxygen', value: '92', icon: Icons.air_sharp, color: Color(0xFF101213)),
  Metric(title: 'Stress Levels', value: '45.6%', icon: FontAwesomeIcons.frown, color: Color(0xFF101213)),
  Metric(title: 'Temperature', value: '56', icon: Icons.thermostat, color: Color(0xFF101213)),
];

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Essential Metrics',
      theme: ThemeData(
        primarySwatch: Colors.red,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1.0,
          titleTextStyle: kEssentialMetricsStyle,
        ),
      ),
      home: MyHomePage(),
    );
  }
}
