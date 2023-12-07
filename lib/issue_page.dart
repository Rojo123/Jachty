import 'package:flutter/material.dart';
import 'package:yacht_rental/db.dart';
import "package:yacht_rental/confirmation_page.dart";
import "package:yacht_rental/constants.dart";

class IssuePage extends StatefulWidget {
  final String qrCode;

  const IssuePage({required this.qrCode});

  @override
  State<IssuePage> createState() => IssuePageState();
}

class IssuePageState extends State<IssuePage> {
  final TextEditingController _descController = TextEditingController();
  String problem = "";
  Widget summary = Container();

  void routeToResult(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfirmationPage())
    );
  }

  void _sendReport(){
    setState(() {
      summary = Center(child: Container(width: 250, height: 200, decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [BoxShadow(color: secondaryColor, spreadRadius: 3)],
        borderRadius: BorderRadius.circular(10)
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Problem: $problem"),

          const SizedBox(height: 10),

          Text(_descController.text),

          const SizedBox(height: 10),

          ElevatedButton(onPressed: () async {
            String query = "UPDATE wypozyczalnia SET komentarz = '$problem:${_descController.text}' WHERE qrcode = ${widget.qrCode}";
            await doQuery(query);

            routeToResult();
          },
          child: const Text("Zatwierdź"))
      ])));
    });
  }

  void _updateProblem(String problemType) {
    setState(() {
      problem = problemType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(data: ThemeData(
      fontFamily: "Alata",

      primarySwatch: Colors.blue,
        
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.copy(const Size(200, 35)),
          backgroundColor: primaryColor,
          foregroundColor: textColor,
          elevation: 10,
        )
      ),

      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: secondaryColor),
        ),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: secondaryColor,
        selectionHandleColor: secondaryColor,
      ),
    ),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Zgłoś problem'),
      ),
      body: Stack(children: [
        SizedBox.expand(child: FittedBox(fit: BoxFit.fill, child: Image.asset("assets/BackgroundBoat.jpg"))),

        Center(child: Container(width: 300, height: 550, decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [BoxShadow(color: secondaryColor, spreadRadius: 3)],
          borderRadius: BorderRadius.circular(10)
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Text("Nr. jachtu: ${widget.qrCode}"),
            
            const SizedBox(height: 5),

            ElevatedButton(
              onPressed: () {
                _updateProblem("Napęd");
              },
              child: const Text('Uszkodzony napęd'),
            ),

            ElevatedButton(
              onPressed: () {
                _updateProblem("Elektronika");
              },
              child: const Text('Elektronika'),
            ),
            
            ElevatedButton(
              onPressed: () {
                 _updateProblem("Bezpieczeństwo");
              },
              child: const Text('Bezpieczeństwo'),
            ),

            ElevatedButton(
              onPressed: () {
                _updateProblem("Inne");
              },
              child: const Text('Inny problem'),
            ),
            
            const SizedBox(height: 20),

            Text("Wybrany problem: $problem"),

            const SizedBox(height: 10),

            const Text('Opisz problem:'),

            const SizedBox(height: 5),

            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                iconColor: primaryColor,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                  _sendReport();
              },
              child: const Text('Zgłoś usterkę'),
            )
          ]
        ))),
        
        if(summary != Container()) summary
      ])
    ));
  }
}