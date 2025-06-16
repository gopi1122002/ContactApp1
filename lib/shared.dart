import 'package:flutter/material.dart';

// Sanitize strings to remove invalid UTF-16 characters
String sanitizeString(String input) {
  return input.replaceAll(RegExp(r'[\uD800-\uDFFF]'), '?').replaceAll('\ufffd', '?');
}

// Define letter colors at the file level
final Map<String, Color> letterColors = {
  'A': Colors.blue,
  'B': Colors.green,
  'C': Colors.blueAccent,
  'D': Colors.pink,
  'E': Colors.cyan,
  'F': Colors.amber,
  'G': Colors.purple,
  'H': Colors.teal,
  'I': Colors.greenAccent,
  'J': Colors.orange,
  'K': Colors.indigo,
  'L': Colors.red,
  'M': Colors.blue,
  'N': Colors.green,
  'O': Colors.yellow,
  'P': Colors.blueAccent,
  'Q': Colors.cyan,
  'R': Colors.amber,
  'S': Colors.purple,
  'T': Colors.teal,
  'U': Colors.yellow,
  'V': Colors.orange,
  'W': Colors.indigo,
  'X': Colors.redAccent,
  'Y': Colors.blueAccent,
  'Z': Colors.green,
};