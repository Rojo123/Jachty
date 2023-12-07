import "package:flutter/material.dart";
import "package:yacht_rental/db.dart";

class CheckInfoPage extends StatefulWidget {
  const CheckInfoPage({Key? key}) : super(key: key);

  @override
  State<CheckInfoPage> createState() => CheckInfoPageState();
}

class CheckInfoPageState extends State<CheckInfoPage> {
  List<Widget> data = [];

  void update() async {
    var result = await doQuery("SELECT id, jacht, qrcode, status, gps, komentarz FROM wypozyczalnia");

    for(var row in result){
      data.add(Column(children: [
        Row(children: [
          Text(row[0].toString() + " " + row[1]),
        ]),
        Row(children: [
          Text(row[2] + " " + row[3].toString()),
        ]),
        Row(children: [
          Text(row[4] + " " + row[5]),
        ])
      ]));
    }

    setState(() {
      
    });
  }

  @override
  void initState() {
    super.initState();
    update();
  }
  
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text("Text")),
      body: Column(children: data)
    );
  }
}