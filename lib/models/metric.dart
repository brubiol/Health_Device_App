import 'package:flutter/material.dart';

class Metric {
  String title;
  String value;
  IconData icon;
  Color color;

  Metric(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});
}
