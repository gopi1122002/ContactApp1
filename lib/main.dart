import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:listdemo/slidebar.dart';
import 'package:permission_handler/permission_handler.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyContact(title: '',),
      debugShowCheckedModeBanner: false,
    );
  }
}
