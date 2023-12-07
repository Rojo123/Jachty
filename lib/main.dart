import 'package:flutter/material.dart';
import 'dart:isolate';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:yacht_rental/constants.dart';
import 'package:yacht_rental/map_page.dart';

class IsolateStateNotifier with ChangeNotifier {
  Isolate? _isolate;
  Isolate? get isolate => _isolate;

  final StreamController<String> _timeoutController = StreamController<String>.broadcast();
  Stream<String> get timeoutStream => _timeoutController.stream;


  @override
  void dispose(){
    _timeoutController.close();
    _isolate?.kill();
    super.dispose();
  }

  void startIsolate() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_startTimer, receivePort.sendPort);
    notifyListeners();
  }

  void _startTimer(SendPort sendPort){
    Future.delayed(const Duration(seconds: 20), (){ //CHANGE
      sendPort.send("Timeout");
    });
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => IsolateStateNotifier(),
      child: const MyApp(),
    )
  );
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
