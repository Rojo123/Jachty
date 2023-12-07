import 'package:flutter/material.dart';
import 'package:yacht_rental/constants.dart';
import 'package:yacht_rental/map_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wypożyczanie Jachtów',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Alata",

        primarySwatch: Colors.blue,
        
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: textColor,
          elevation: 0,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: textColor,
            elevation: 10,
          ),
        ),
      ),
      home: const MapPage(),
    );
  }
}
