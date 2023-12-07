import "package:flutter/material.dart";
import "dart:async";
import "package:yacht_rental/constants.dart";

class ConfirmationPage extends StatefulWidget {
  const ConfirmationPage({super.key});

  @override
  State<ConfirmationPage> createState() => ConfirmationPageState();
}

class ConfirmationPageState extends State<ConfirmationPage> {

  void handleTimeout(){
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Timer scheduleTimeout([int milliseconds = 1000]) => Timer(Duration(milliseconds: milliseconds), handleTimeout);

  @override
  Widget build(BuildContext context){
    scheduleTimeout(5 * 1000);
    return Scaffold(
      appBar: AppBar(title: const Text("Przetwarzanie...")),
      body: Stack(children: [
        SizedBox.expand(child: FittedBox(fit: BoxFit.fill, child: Image.asset("assets/BackgroundBoat.jpg"))),


        Center(child: Container(width: 300, height: 300, decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [BoxShadow(color: secondaryColor, spreadRadius: 3)],
          borderRadius: BorderRadius.circular(10)
          ),
          child:
            const Column(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, children: [
              CircularProgressIndicator(color: secondaryColor),
              Text("Przetwarzanie...")
        ])
        ))
    ]));
  }
}