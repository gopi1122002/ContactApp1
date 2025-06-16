import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contact.dart';
import 'Theme.dart';
void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: const MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Contact App',
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const MyContact(title: 'Contacts'),
      debugShowCheckedModeBanner: false,
    );
  }
}